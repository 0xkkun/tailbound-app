import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 보상형 광고 타입
enum RewardAdType {
  artifact, // 유물
  revival, // 부활
  reroll, // 리롤
  bundle, // 도깨비 보따리
}

/// 전면 광고 타입
enum InterstitialAdType {
  gameInterstitial, // 게임 중 전면 광고
}

/// 배너 광고 타입
enum BannerAdType {
  exitPopup, // 종료 팝업 내 배너
}

/// 광고 매니저 클래스
class AdManager {
  // 싱글톤 패턴
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  // 테스트 광고 ID (Google 공식)
  static const String _testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';

  // iOS 광고 Unit IDs
  static const Map<RewardAdType, String> _iosAdUnitIds = {
    RewardAdType.artifact: 'ca-app-pub-2202284171552842/5443086569',
    RewardAdType.revival: 'ca-app-pub-2202284171552842/9888871680',
    RewardAdType.reroll: 'ca-app-pub-2202284171552842/9114303494',
    RewardAdType.bundle: 'ca-app-pub-2202284171552842/5443086569', // 유물 광고와 동일
  };

  // Android 광고 Unit IDs
  static const Map<RewardAdType, String> _androidAdUnitIds = {
    RewardAdType.artifact: 'ca-app-pub-2202284171552842/1063890252',
    RewardAdType.revival: 'ca-app-pub-2202284171552842/4464513983',
    RewardAdType.reroll: 'ca-app-pub-2202284171552842/6886770996',
    RewardAdType.bundle: 'ca-app-pub-2202284171552842/1063890252', // 유물 광고와 동일
  };

  // iOS 전면 광고 Unit IDs
  static const Map<InterstitialAdType, String> _iosInterstitialAdUnitIds = {
    InterstitialAdType.gameInterstitial:
        'ca-app-pub-2202284171552842/1084947264',
  };

  // Android 전면 광고 Unit IDs (iOS와 동일 — iOS 전용 앱이므로 추후 분리)
  static const Map<InterstitialAdType, String> _androidInterstitialAdUnitIds = {
    InterstitialAdType.gameInterstitial:
        'ca-app-pub-2202284171552842/1084947264',
  };

  // iOS 배너 광고 Unit IDs
  static const Map<BannerAdType, String> _iosBannerAdUnitIds = {
    BannerAdType.exitPopup: 'ca-app-pub-2202284171552842/6169016891',
  };

  // Android 배너 광고 Unit IDs
  static const Map<BannerAdType, String> _androidBannerAdUnitIds = {
    BannerAdType.exitPopup: 'ca-app-pub-2202284171552842/6169016891',
  };

  /// 플랫폼 및 디버그 모드에 따른 보상형 광고 ID 반환
  static String _getRewardedAdUnitId(RewardAdType type) {
    if (kDebugMode) return _testRewardedAdUnitId;
    if (Platform.isIOS) return _iosAdUnitIds[type]!;
    if (Platform.isAndroid) return _androidAdUnitIds[type]!;
    return _testRewardedAdUnitId;
  }

  /// 플랫폼 및 디버그 모드에 따른 전면 광고 ID 반환
  static String _getInterstitialAdUnitId(InterstitialAdType type) {
    if (kDebugMode) return _testInterstitialAdUnitId;
    if (Platform.isIOS) return _iosInterstitialAdUnitIds[type]!;
    if (Platform.isAndroid) return _androidInterstitialAdUnitIds[type]!;
    return _testInterstitialAdUnitId;
  }

  /// 플랫폼 및 디버그 모드에 따른 배너 광고 ID 반환
  static String _getBannerAdUnitId(BannerAdType type) {
    if (kDebugMode) return _testBannerAdUnitId;
    if (Platform.isIOS) return _iosBannerAdUnitIds[type]!;
    if (Platform.isAndroid) return _androidBannerAdUnitIds[type]!;
    return _testBannerAdUnitId;
  }

  // 현재 로드된 보상형 광고
  final Map<RewardAdType, RewardedAd?> _loadedAds = {};
  final Map<RewardAdType, bool> _isLoading = {};

  // 현재 로드된 전면 광고
  final Map<InterstitialAdType, InterstitialAd?> _loadedInterstitialAds = {};
  final Map<InterstitialAdType, bool> _isInterstitialLoading = {};

  /// 특정 타입의 광고 미리 로드
  Future<void> preloadAd(RewardAdType type) async {
    // 이미 로드 중이거나 로드되어 있으면 스킵
    if (_isLoading[type] == true || _loadedAds[type] != null) {
      debugPrint('Ad already loaded or loading: $type');
      return;
    }

    _isLoading[type] = true;
    debugPrint('Loading rewarded ad: $type');

    await RewardedAd.load(
      adUnitId: _getRewardedAdUnitId(type),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Rewarded ad loaded: $type');
          _loadedAds[type] = ad;
          _isLoading[type] = false;

          // 광고가 닫힐 때 정리
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('Rewarded ad dismissed: $type');
              ad.dispose();
              _loadedAds[type] = null;
              // 다음 광고 미리 로드
              preloadAd(type);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Failed to show rewarded ad: $type, error: $error');
              ad.dispose();
              _loadedAds[type] = null;
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Failed to load rewarded ad: $type, error: $error');
          _isLoading[type] = false;
        },
      ),
    );
  }

  /// 모든 광고 미리 로드
  Future<void> preloadAllAds() async {
    await Future.wait([
      preloadAd(RewardAdType.artifact),
      preloadAd(RewardAdType.revival),
      preloadAd(RewardAdType.reroll),
      preloadAd(RewardAdType.bundle),
    ]);
  }

  /// 광고가 로드되어 있는지 확인
  bool isAdReady(RewardAdType type) {
    return _loadedAds[type] != null;
  }

  /// 광고 표시 및 보상 콜백 (광고가 닫힐 때까지 대기)
  Future<bool> showRewardedAd(
    RewardAdType type, {
    required Function(String rewardType, int rewardAmount) onRewarded,
    Function()? onAdClosed,
  }) async {
    final ad = _loadedAds[type];

    if (ad == null) {
      debugPrint('Ad not ready: $type');
      // 광고가 없으면 다시 로드 시도
      await preloadAd(type);
      return false;
    }

    // Completer로 광고가 닫힐 때까지 기다림
    final completer = Completer<bool>();
    bool rewarded = false;

    // 보상 콜백 설정
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('Rewarded ad showed: $type');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('Rewarded ad dismissed: $type (rewarded: $rewarded)');
        ad.dispose();
        _loadedAds[type] = null;
        onAdClosed?.call();
        // 다음 광고 미리 로드
        preloadAd(type);
        // Completer 완료
        if (!completer.isCompleted) {
          completer.complete(rewarded);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Failed to show rewarded ad: $type, error: $error');
        ad.dispose();
        _loadedAds[type] = null;
        onAdClosed?.call();
        // Completer 완료 (실패)
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
    );

    // 광고 표시
    await ad.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint(
          'User earned reward: ${reward.type}, amount: ${reward.amount}',
        );
        rewarded = true;
        onRewarded(reward.type, reward.amount.toInt());
      },
    );

    // 광고가 닫힐 때까지 기다림
    return completer.future;
  }

  // ─── 전면 광고 (Interstitial) ───

  /// 전면 광고 미리 로드
  Future<void> preloadInterstitialAd(InterstitialAdType type) async {
    if (_isInterstitialLoading[type] == true ||
        _loadedInterstitialAds[type] != null) {
      return;
    }

    _isInterstitialLoading[type] = true;
    debugPrint('Loading interstitial ad: $type');

    await InterstitialAd.load(
      adUnitId: _getInterstitialAdUnitId(type),
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Interstitial ad loaded: $type');
          _loadedInterstitialAds[type] = ad;
          _isInterstitialLoading[type] = false;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('Interstitial ad dismissed: $type');
              ad.dispose();
              _loadedInterstitialAds[type] = null;
              preloadInterstitialAd(type);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint(
                'Failed to show interstitial ad: $type, error: $error',
              );
              ad.dispose();
              _loadedInterstitialAds[type] = null;
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Failed to load interstitial ad: $type, error: $error');
          _isInterstitialLoading[type] = false;
        },
      ),
    );
  }

  /// 전면 광고 로드 여부
  bool isInterstitialAdReady(InterstitialAdType type) {
    return _loadedInterstitialAds[type] != null;
  }

  /// 전면 광고 표시 (광고가 닫힐 때까지 대기)
  Future<bool> showInterstitialAd(InterstitialAdType type) async {
    final ad = _loadedInterstitialAds[type];

    if (ad == null) {
      debugPrint('Interstitial ad not ready: $type');
      return false;
    }

    final completer = Completer<bool>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('Interstitial ad showed: $type');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('Interstitial ad dismissed: $type');
        ad.dispose();
        _loadedInterstitialAds[type] = null;
        preloadInterstitialAd(type);
        if (!completer.isCompleted) completer.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Failed to show interstitial ad: $type, error: $error');
        ad.dispose();
        _loadedInterstitialAds[type] = null;
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    await ad.show();
    return completer.future;
  }

  /// 배너 광고 생성 (다이얼로그 등에 삽입용)
  BannerAd createBannerAd(
    BannerAdType type, {
    AdSize size = AdSize.mediumRectangle,
  }) {
    return BannerAd(
      adUnitId: _getBannerAdUnitId(type),
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Banner ad loaded: $type');
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Failed to load banner ad: $type, error: $error');
          ad.dispose();
        },
      ),
    );
  }

  /// 정리
  void dispose() {
    for (var ad in _loadedAds.values) {
      ad?.dispose();
    }
    _loadedAds.clear();
    for (var ad in _loadedInterstitialAds.values) {
      ad?.dispose();
    }
    _loadedInterstitialAds.clear();
  }
}
