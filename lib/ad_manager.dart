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

/// 광고 매니저 클래스
class AdManager {
  // 싱글톤 패턴
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  // 테스트 광고 ID (Google 공식)
  static const String _testAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  // iOS 광고 Unit IDs
  static const Map<RewardAdType, String> _iosAdUnitIds = {
    RewardAdType.artifact: 'ca-app-pub-2202284171552842/5443086569',
    RewardAdType.revival: 'ca-app-pub-2202284171552842/9888871680',
    RewardAdType.reroll: 'ca-app-pub-2202284171552842/9114303494',
    // TODO: AdMob 콘솔에서 도깨비 보따리 ad unit 생성 후 교체
    RewardAdType.bundle: 'ca-app-pub-3940256099942544/5224354917', // 테스트 ID
  };

  // Android 광고 Unit IDs
  static const Map<RewardAdType, String> _androidAdUnitIds = {
    RewardAdType.artifact: 'ca-app-pub-2202284171552842/1063890252',
    RewardAdType.revival: 'ca-app-pub-2202284171552842/4464513983',
    RewardAdType.reroll: 'ca-app-pub-2202284171552842/6886770996',
    // TODO: AdMob 콘솔에서 도깨비 보따리 ad unit 생성 후 교체
    RewardAdType.bundle: 'ca-app-pub-3940256099942544/5224354917', // 테스트 ID
  };

  /// 플랫폼 및 디버그 모드에 따른 광고 ID 반환
  static String _getAdUnitId(RewardAdType type) {
    // Debug 모드: 테스트 광고
    if (kDebugMode) {
      return _testAdUnitId;
    }

    // Release 모드: 플랫폼별 실제 광고
    if (Platform.isIOS) {
      return _iosAdUnitIds[type]!;
    } else if (Platform.isAndroid) {
      return _androidAdUnitIds[type]!;
    }

    // Fallback (테스트 ID)
    return _testAdUnitId;
  }

  // 현재 로드된 광고들
  final Map<RewardAdType, RewardedAd?> _loadedAds = {};

  // 광고 로드 중 상태
  final Map<RewardAdType, bool> _isLoading = {};

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
      adUnitId: _getAdUnitId(type),
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

  /// 정리
  void dispose() {
    for (var ad in _loadedAds.values) {
      ad?.dispose();
    }
    _loadedAds.clear();
  }
}
