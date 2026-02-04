import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ad_manager.dart';

/// Flutter Bridge Service
/// 웹 게임과 네이티브 기능 간의 통합 브리지
class BridgeService {
  final WebViewController webViewController;

  BridgeService(this.webViewController);

  /// JavaScript Channel 메시지 핸들러
  Future<void> handleMessage(String message) async {
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      final id = data['id'] as String;
      final type = data['type'] as String;
      final payload = data['payload'] as Map<String, dynamic>;

      debugPrint('[Bridge] Received: $type (id: $id)');

      dynamic result;
      try {
        switch (type) {
          case 'ad.request':
            result = await _handleAdRequest(payload);
            break;
          case 'safeArea.get':
            result = await _getSafeArea();
            break;
          case 'storage.set':
            result = await _setStorage(payload);
            break;
          case 'storage.get':
            result = await _getStorage(payload);
            break;
          case 'haptic.impact':
            result = await _triggerHaptic(payload);
            break;
          case 'share.open':
            result = await _shareContent(payload);
            break;
          case 'analytics.click':
            result = await _handleAnalyticsClick(payload);
            break;
          case 'analytics.impression':
            result = await _handleAnalyticsImpression(payload);
            break;
          case 'gameCenter.openLeaderboard':
            result = await _handleGameCenterOpenLeaderboard();
            break;
          case 'gameCenter.submitScore':
            result = await _handleGameCenterSubmitScore(payload);
            break;
          default:
            throw Exception('Unknown command: $type');
        }

        await _sendResult(id, type, success: true, data: result);
      } catch (e) {
        debugPrint('[Bridge] Error handling $type: $e');
        await _sendResult(id, type, success: false, error: e.toString());
      }
    } catch (e) {
      debugPrint('[Bridge] Failed to parse message: $e');
    }
  }

  /// 광고 요청 처리
  Future<Map<String, dynamic>> _handleAdRequest(
    Map<String, dynamic> payload,
  ) async {
    final adTypeStr = payload['adType'] as String;
    debugPrint('[Bridge] Ad request: $adTypeStr');

    RewardAdType? adType;
    switch (adTypeStr.toLowerCase()) {
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
        throw Exception('Unknown ad type: $adTypeStr');
    }

    if (!AdManager().isAdReady(adType)) {
      throw Exception('Ad not ready: $adTypeStr');
    }

    bool rewarded = false;
    final success = await AdManager().showRewardedAd(
      adType,
      onRewarded: (rewardType, rewardAmount) {
        debugPrint('[Bridge] Rewarded: $rewardType, amount: $rewardAmount');
        rewarded = true;
      },
      onAdClosed: () {
        debugPrint('[Bridge] Ad closed');
      },
    );

    return {'success': success, 'rewarded': rewarded};
  }

  /// Safe Area 조회
  Future<Map<String, dynamic>> _getSafeArea() async {
    // MediaQuery를 사용할 수 없으므로, 플랫폼별 기본값 반환
    // 실제 값은 앱 초기화 시 주입됨 (__APP_ENV__)
    return {
      'top': Platform.isIOS ? 47.0 : 0.0,
      'bottom': Platform.isIOS ? 34.0 : 0.0,
      'left': 0.0,
      'right': 0.0,
    };
  }

  /// 로컬 스토리지 저장
  Future<Map<String, dynamic>> _setStorage(Map<String, dynamic> payload) async {
    final key = payload['key'] as String;
    final value = payload['value'] as String;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);

    debugPrint('[Bridge] Storage set: $key');

    return {'success': true};
  }

  /// 로컬 스토리지 조회
  Future<Map<String, dynamic>> _getStorage(Map<String, dynamic> payload) async {
    final key = payload['key'] as String;

    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(key);

    debugPrint('[Bridge] Storage get: $key = $value');

    return {'value': value};
  }

  /// 햅틱 피드백
  Future<Map<String, dynamic>> _triggerHaptic(
    Map<String, dynamic> payload,
  ) async {
    final style = payload['style'] as String;

    switch (style) {
      case 'light':
        await HapticFeedback.lightImpact();
        break;
      case 'medium':
        await HapticFeedback.mediumImpact();
        break;
      case 'heavy':
        await HapticFeedback.heavyImpact();
        break;
      default:
        await HapticFeedback.mediumImpact();
    }

    debugPrint('[Bridge] Haptic: $style');

    return {'success': true};
  }

  /// 공유 다이얼로그
  Future<Map<String, dynamic>> _shareContent(
    Map<String, dynamic> payload,
  ) async {
    final url = payload['url'] as String;
    final title = payload['title'] as String?;

    final text = title != null ? '$title\n$url' : url;
    await Share.share(text);

    debugPrint('[Bridge] Share: $url');

    return {'success': true};
  }

  /// Analytics 클릭 이벤트 (더미 구현)
  Future<Map<String, dynamic>> _handleAnalyticsClick(
    Map<String, dynamic> payload,
  ) async {
    final params = payload['params'] as Map<String, dynamic>?;
    debugPrint('[Bridge] Analytics Click (not implemented): $params');
    return {'success': true};
  }

  /// Analytics 노출 이벤트 (더미 구현)
  Future<Map<String, dynamic>> _handleAnalyticsImpression(
    Map<String, dynamic> payload,
  ) async {
    final params = payload['params'] as Map<String, dynamic>?;
    debugPrint('[Bridge] Analytics Impression (not implemented): $params');
    return {'success': true};
  }

  /// Game Center 리더보드 열기 (더미 구현)
  Future<Map<String, dynamic>> _handleGameCenterOpenLeaderboard() async {
    debugPrint('[Bridge] Game Center Open Leaderboard (not implemented)');
    return {'success': false};
  }

  /// Game Center 점수 제출 (더미 구현)
  Future<Map<String, dynamic>> _handleGameCenterSubmitScore(
    Map<String, dynamic> payload,
  ) async {
    final score = payload['score'] as String?;
    debugPrint('[Bridge] Game Center Submit Score (not implemented): $score');
    return {'success': false, 'submitted': false};
  }

  /// 결과를 WebView로 전송 (CustomEvent)
  Future<void> _sendResult(
    String id,
    String type, {
    required bool success,
    dynamic data,
    String? error,
  }) async {
    final result = {
      'id': id,
      'type': type,
      'success': success,
      'data': data,
      'error': error,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    final resultJson = jsonEncode(result);
    final js =
        '''
      window.dispatchEvent(new CustomEvent('flutterBridgeResult', {
        detail: $resultJson
      }));
    ''';

    await webViewController.runJavaScript(js);
    debugPrint('[Bridge] Result sent: $type (success: $success)');
  }
}
