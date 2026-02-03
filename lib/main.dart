import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_manager.dart';

// 백그라운드 메시지 핸들러
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 가로 모드 방지 및 세로 모드 고정
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Firebase 초기화 (실제 Firebase 프로젝트 없이도 컴파일 가능하도록 try-catch)
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 푸시 알림 권한 요청
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // FCM 토큰 가져오기
    final token = await messaging.getToken();
    debugPrint('FCM Token: $token');
  } catch (e) {
    debugPrint('Firebase initialization skipped: $e');
  }

  // AdMob 초기화
  await MobileAds.instance.initialize();
  debugPrint('AdMob initialized');

  // 광고 미리 로드
  AdManager().preloadAllAds();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tailbound',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const WebViewPage(),
    );
  }
}

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  /// WebView에서 광고 요청 처리
  void _handleAdRequest(String message) async {
    debugPrint('Ad request from WebView: $message');

    // 메시지 파싱 (예: "artifact", "revival", "reroll")
    RewardAdType? adType;
    switch (message.toLowerCase()) {
      case 'artifact':
        adType = RewardAdType.artifact;
        break;
      case 'revival':
        adType = RewardAdType.revival;
        break;
      case 'reroll':
        adType = RewardAdType.reroll;
        break;
      default:
        debugPrint('Unknown ad type: $message');
        _sendAdResultToWebView(message, false, 'Unknown ad type');
        return;
    }

    // 광고가 준비되었는지 확인
    if (!AdManager().isAdReady(adType)) {
      debugPrint('Ad not ready: $adType');
      _sendAdResultToWebView(message, false, 'Ad not ready');
      return;
    }

    // 광고 표시
    final success = await AdManager().showRewardedAd(
      adType,
      onRewarded: (rewardType, rewardAmount) {
        debugPrint('Rewarded: $rewardType, amount: $rewardAmount');
        _sendAdResultToWebView(message, true, 'Success');
      },
      onAdClosed: () {
        debugPrint('Ad closed');
      },
    );

    if (!success) {
      _sendAdResultToWebView(message, false, 'Failed to show ad');
    }
  }

  /// 광고 결과를 WebView로 전달
  void _sendAdResultToWebView(String adType, bool success, String message) {
    final js = '''
      if (window.onAdResult) {
        window.onAdResult({
          adType: "$adType",
          success: $success,
          message: "$message"
        });
      }
    ''';
    _controller.runJavaScript(js);
  }

  void _initializeWebView() {
    // iOS/Android용 플랫폼별 설정
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'FlutterAd',
        onMessageReceived: (JavaScriptMessage message) {
          _handleAdRequest(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Web resource error: ${error.description}');
            debugPrint('Failed URL: ${error.url}');
            debugPrint('Error type: ${error.errorType}');
            debugPrint('Error code: ${error.errorCode}');
            
            // 오디오/비디오 파일 로딩 에러는 무시 (게임은 계속 진행)
            final url = error.url?.toLowerCase() ?? '';
            final isMediaFile = url.endsWith('.mp3') || 
                                url.endsWith('.mp4') || 
                                url.endsWith('.wav') || 
                                url.endsWith('.ogg') ||
                                url.endsWith('.webm');
            
            // 미디어 파일이 아닌 경우에만 에러 표시
            if (!isMediaFile && mounted) {
              setState(() {
                _errorMessage = '${error.description}\nURL: ${error.url}';
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('Navigation request: ${request.url}');
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://tailbound.vercel.app'));

    // Android용 WebGL 및 하드웨어 가속 설정
    if (_controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      final androidController = _controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
      
      // WebView 추가 설정
      androidController.setGeolocationPermissionsPromptCallbacks(
        onShowPrompt: (request) async {
          return GeolocationPermissionsResponse(
            allow: false,
            retain: false,
          );
        },
      );
    }

    // iOS용 추가 설정
    if (_controller.platform is WebKitWebViewController) {
      (_controller.platform as WebKitWebViewController)
          .setAllowsBackForwardNavigationGestures(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) async {
                if (didPop) return;
                if (await _controller.canGoBack()) {
                  await _controller.goBack();
                } else {
                  // 더 이상 뒤로 갈 수 없으면 앱 종료 (기본 동작 수행을 위해 canPop을 활용하거나 직접 종료 제어 가능)
                  if (context.mounted) {
                    SystemNavigator.pop();
                  }
                }
              },
              child: WebViewWidget(controller: _controller),
            ),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            if (_errorMessage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading page',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _errorMessage = null;
                          });
                          _controller.reload();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
