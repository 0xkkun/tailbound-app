import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_manager.dart';
import 'services/bridge_service.dart';

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
  late final BridgeService _bridgeService;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  /// 앱 환경 정보를 WebView에 주입
  Future<void> _injectAppEnvironment() async {
    // viewPadding: 시스템 UI(노치, 네비게이션 바)만 고려 (키보드 제외)
    final safeAreaTop = MediaQuery.of(context).viewPadding.top;
    final safeAreaBottom = MediaQuery.of(context).viewPadding.bottom;
    final safeAreaLeft = MediaQuery.of(context).viewPadding.left;
    final safeAreaRight = MediaQuery.of(context).viewPadding.right;

    final js =
        '''
      window.__APP_ENV__ = {
        platform: 'flutter',
        os: '${Platform.isIOS ? 'ios' : 'android'}',
        version: '1.0.0',
        safeArea: {
          top: $safeAreaTop,
          bottom: $safeAreaBottom,
          left: $safeAreaLeft,
          right: $safeAreaRight
        }
      };
      console.log('[Flutter] App environment injected:', window.__APP_ENV__);
    ''';

    await _controller.runJavaScript(js);
    debugPrint('[Flutter] App environment injected');
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
        'FlutterBridge',
        onMessageReceived: (JavaScriptMessage message) {
          _bridgeService.handleMessage(message.message);
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
          onPageFinished: (String url) async {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });

              // 앱 환경 정보 주입
              await _injectAppEnvironment();
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Web resource error: ${error.description}');
            debugPrint('Failed URL: ${error.url}');
            debugPrint('Error type: ${error.errorType}');
            debugPrint('Error code: ${error.errorCode}');

            // 오디오/비디오 파일 로딩 에러는 무시 (게임은 계속 진행)
            final url = error.url?.toLowerCase() ?? '';
            final isMediaFile =
                url.endsWith('.mp3') ||
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
      ..loadRequest(
        Uri.parse(
          kDebugMode
              // Android Emulator: 10.0.2.2 = localhost
              // iOS Simulator: localhost or 127.0.0.1
              // Real Device: Use your machine's IP (e.g., 192.168.x.x)
              ? 'http://10.0.2.2:5173/'
              : 'https://tailbound.vercel.app',
        ),
      );

    // Android용 WebGL 및 하드웨어 가속 설정
    if (_controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      final androidController =
          _controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);

      // WebView 추가 설정
      androidController.setGeolocationPermissionsPromptCallbacks(
        onShowPrompt: (request) async {
          return GeolocationPermissionsResponse(allow: false, retain: false);
        },
      );
    }

    // iOS용 추가 설정
    if (_controller.platform is WebKitWebViewController) {
      (_controller.platform as WebKitWebViewController)
          .setAllowsBackForwardNavigationGestures(true);
    }

    // BridgeService 초기화
    _bridgeService = BridgeService(_controller);
  }

  /// 앱 종료 확인 다이얼로그 (전면 광고 → 종료)
  Future<void> _showExitConfirmDialog() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('종료'),
          content: const Text('게임을 종료하시겠습니까?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                '종료',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (shouldExit == true) {
      // 전면 광고가 준비되어 있으면 보여주고 종료
      final adManager = AdManager();
      if (adManager.isInterstitialAdReady(InterstitialAdType.exitPopup)) {
        await adManager.showInterstitialAd(InterstitialAdType.exitPopup);
      }
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              if (await _controller.canGoBack()) {
                await _controller.goBack();
              } else {
                // 더 이상 뒤로 갈 수 없으면 종료 확인 다이얼로그 표시
                if (context.mounted) {
                  await _showExitConfirmDialog();
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
    );
  }
}
