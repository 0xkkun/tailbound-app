import 'dart:async';
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
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'ad_manager.dart';
import 'l10n/app_localizations.dart';
import 'services/bridge_service.dart';
import 'services/preferences_service.dart';
import 'widgets/exit_confirm_dialog.dart';

/// 디버그 모드에서 사용할 URL (--dart-define=DEBUG_URL=... 로 오버라이드 가능)
const debugUrl = String.fromEnvironment(
  'DEBUG_URL',
  defaultValue: 'http://localhost:5173/',
);

// 백그라운드 메시지 핸들러
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global error handlers
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[GlobalError] Flutter error: ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('[GlobalError] Unhandled error: $error\n$stack');
    return true;
  };

  // 가로 모드 방지 및 세로 모드 고정
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // SharedPreferences 캐싱 초기화
  await PreferencesService.init();

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
  unawaited(AdManager().preloadAllAds());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tailbound',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
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

class _WebViewPageState extends State<WebViewPage> with WidgetsBindingObserver {
  late final WebViewController _controller;
  BridgeService? _bridgeService;
  String _appVersion = '1.0.0';
  bool _isLoading = true;
  String? _errorMessage;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAsync();
  }

  Future<void> _initAsync() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = '${info.version}+${info.buildNumber}';
    } catch (e) {
      debugPrint('PackageInfo failed: $e');
    }
    if (!mounted) return;
    _initializeWebView();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 앱 생명주기 변경 → WebView 게임 pause/resume
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _bridgeService?.pauseGame();
        break;
      case AppLifecycleState.resumed:
        _bridgeService?.resumeGame();
        break;
      default:
        break;
    }
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
        version: '$_appVersion',
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
          _bridgeService?.handleMessage(message.message);
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
            // JS 실행 전에 __APP_ENV__ 주입 (싱글톤 초기화보다 먼저)
            _injectAppEnvironment();
          },
          onPageFinished: (String url) async {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });

              // safe area는 layout 완료 후 정확한 값으로 재주입
              await _injectAppEnvironment();
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Web resource error: ${error.description}');
            debugPrint('Failed URL: ${error.url}');
            debugPrint('Error type: ${error.errorType}');
            debugPrint('Error code: ${error.errorCode}');
            debugPrint('isForMainFrame: ${error.isForMainFrame}');

            // 메인 프레임 로딩 실패만 에러 표시
            // 서브리소스(이미지, 폰트, API, 광고 SDK 등) 실패는 무시
            if (error.isForMainFrame == true && mounted) {
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
        Uri.parse(kDebugMode ? debugUrl : 'https://tailbound.vercel.app'),
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
          return const GeolocationPermissionsResponse(allow: false, retain: false);
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

  /// 앱 종료 확인 다이얼로그 (배너 광고 포함)
  Future<void> _showExitConfirmDialog() async {
    try {
      final shouldExit = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return const ExitConfirmDialog();
        },
      );

      if (shouldExit == true) {
        SystemNavigator.pop();
      }
    } catch (e) {
      debugPrint('Exit dialog error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        // 웹이 safe area를 직접 처리 (토스/Flutter 환경 공통)
        top: false,
        bottom: false,
        child: Stack(
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
                        AppLocalizations.of(context)?.errorLoadingPage ??
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
                        child: Text(
                          AppLocalizations.of(context)?.errorRetry ?? 'Retry',
                        ),
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
