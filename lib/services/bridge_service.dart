import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../ad_manager.dart';
import '../models/bridge_message.dart';
import 'preferences_service.dart';

/// Flutter Bridge Service
///
/// Provides communication between the WebView-based game and native Flutter
/// capabilities such as ads, storage, haptics, and sharing.
///
/// Messages are received as JSON strings via the `FlutterBridge` JavaScript
/// channel, parsed into [BridgeMessage] instances, routed to the appropriate
/// handler, and results are sent back as [BridgeResponse] via CustomEvent.
class BridgeService {
  /// The [WebViewController] used to communicate with the WebView.
  final WebViewController webViewController;

  /// Creates a [BridgeService] bound to the given [webViewController].
  BridgeService(this.webViewController);

  /// Handles an incoming JSON [message] from the JavaScript bridge.
  ///
  /// Parses the message into a [BridgeMessage], routes it to the appropriate
  /// handler, and sends the result back to the WebView.
  Future<void> handleMessage(String message) async {
    late final BridgeMessage bridgeMessage;
    try {
      final json = jsonDecode(message);
      if (json is! Map<String, dynamic>) {
        debugPrint('[Bridge] Message is not a JSON object');
        return;
      }
      bridgeMessage = BridgeMessage.fromJson(json);
    } on FormatException catch (e) {
      debugPrint('[Bridge] Failed to parse message: $e');
      return;
    }

    debugPrint('[Bridge] Received: ${bridgeMessage.type} (id: ${bridgeMessage.id})');

    try {
      final result = await _routeMessage(bridgeMessage);
      await _sendResponse(
        BridgeResponse.success(bridgeMessage.id, bridgeMessage.type, data: result),
      );
    } catch (e) {
      debugPrint('[Bridge] Error handling ${bridgeMessage.type}: $e');
      await _sendResponse(
        BridgeResponse.failure(bridgeMessage.id, bridgeMessage.type, e.toString()),
      );
    }
  }

  /// Routes a [BridgeMessage] to the correct handler based on its type.
  Future<Map<String, dynamic>> _routeMessage(BridgeMessage msg) async {
    switch (msg.type) {
      case 'ad.request':
        return _handleAdRequest(msg);
      case 'ad.preload':
        return _handleAdPreload(msg);
      case 'safeArea.get':
        return _getSafeArea();
      case 'storage.set':
        return _setStorage(msg);
      case 'storage.get':
        return _getStorage(msg);
      case 'storage.remove':
        return _removeStorage(msg);
      case 'haptic.impact':
        return _triggerHaptic(msg);
      case 'share.open':
        return _shareContent(msg);
      case 'analytics.click':
        return _handleAnalyticsClick(msg);
      case 'analytics.impression':
        return _handleAnalyticsImpression(msg);
      case 'gameCenter.openLeaderboard':
        return _handleGameCenterOpenLeaderboard();
      case 'gameCenter.submitScore':
        return _handleGameCenterSubmitScore(msg);
      default:
        throw Exception('Unknown command: ${msg.type}');
    }
  }

  /// Handles a rewarded ad request.
  Future<Map<String, dynamic>> _handleAdRequest(BridgeMessage msg) async {
    final adTypeStr = msg.getString('adType');
    debugPrint('[Bridge] Ad request: $adTypeStr');

    final adType = AdManager.parseRewardAdType(adTypeStr);
    if (adType == null) throw Exception('Unknown ad type: $adTypeStr');

    if (!AdManager().isAdReady(adType)) {
      throw Exception('Ad not ready: $adTypeStr');
    }

    await pauseGame();

    bool rewarded = false;
    final success = await AdManager().showRewardedAd(
      adType,
      onRewarded: (rewardType, rewardAmount) {
        debugPrint('[Bridge] Rewarded: $rewardType, amount: $rewardAmount');
        rewarded = true;
      },
      onAdClosed: () {
        debugPrint('[Bridge] Ad closed');
        resumeGame();
      },
    );

    debugPrint('[Bridge] Ad result: success=$success, rewarded=$rewarded');
    return {'success': success, 'rewarded': rewarded};
  }

  /// Handles an ad preload request.
  Future<Map<String, dynamic>> _handleAdPreload(BridgeMessage msg) async {
    final adTypeStr = msg.getString('adType');
    debugPrint('[Bridge] Ad preload request: $adTypeStr');

    final adType = AdManager.parseRewardAdType(adTypeStr);
    if (adType == null) throw Exception('Unknown ad type: $adTypeStr');

    await AdManager().preloadAd(adType);
    return {'success': true};
  }

  /// Returns the device safe area insets.
  Future<Map<String, dynamic>> _getSafeArea() async {
    return {
      'top': Platform.isIOS ? 47.0 : 0.0,
      'bottom': Platform.isIOS ? 34.0 : 0.0,
      'left': 0.0,
      'right': 0.0,
    };
  }

  /// Stores a key-value pair in local storage.
  Future<Map<String, dynamic>> _setStorage(BridgeMessage msg) async {
    final key = msg.getString('key');
    final value = msg.getString('value');

    final prefs = PreferencesService.instance;
    await prefs.setString(key, value);

    debugPrint('[Bridge] Storage set: $key');
    return {'success': true};
  }

  /// Retrieves a value from local storage.
  Future<Map<String, dynamic>> _getStorage(BridgeMessage msg) async {
    final key = msg.getString('key');

    final prefs = PreferencesService.instance;
    final value = prefs.getString(key);

    debugPrint('[Bridge] Storage get: $key = $value');
    return {'success': true, 'value': value};
  }

  /// Removes a key from local storage.
  Future<Map<String, dynamic>> _removeStorage(BridgeMessage msg) async {
    final key = msg.getString('key');

    final prefs = PreferencesService.instance;
    await prefs.remove(key);

    debugPrint('[Bridge] Storage remove: $key');
    return {'success': true};
  }

  /// Triggers haptic feedback based on the requested style.
  ///
  /// Supports 7 standard styles plus 3 legacy aliases.
  Future<Map<String, dynamic>> _triggerHaptic(BridgeMessage msg) async {
    final style = msg.getString('style', defaultValue: 'mediumImpact');

    switch (style) {
      case 'selectionClick':
        await HapticFeedback.selectionClick();
      case 'lightImpact':
      case 'light':
        await HapticFeedback.lightImpact();
      case 'mediumImpact':
      case 'medium':
        await HapticFeedback.mediumImpact();
      case 'heavyImpact':
      case 'heavy':
        await HapticFeedback.heavyImpact();
      case 'notificationSuccess':
        await HapticFeedback.lightImpact();
      case 'notificationWarning':
        await HapticFeedback.mediumImpact();
      case 'notificationError':
        await HapticFeedback.heavyImpact();
      default:
        await HapticFeedback.mediumImpact();
    }

    debugPrint('[Bridge] Haptic: $style');
    return {'success': true};
  }

  /// Opens the native share dialog.
  Future<Map<String, dynamic>> _shareContent(BridgeMessage msg) async {
    final url = msg.getString('url');
    final title = msg.getStringOrNull('title');

    final text = title != null ? '$title\n$url' : url;
    await Share.share(text);

    debugPrint('[Bridge] Share: $url');
    return {'success': true};
  }

  /// Handles an analytics click event (stub implementation).
  Future<Map<String, dynamic>> _handleAnalyticsClick(BridgeMessage msg) async {
    final params = msg.getMapOrNull('params');
    debugPrint('[Bridge] Analytics Click (not implemented): $params');
    return {'success': true};
  }

  /// Handles an analytics impression event (stub implementation).
  Future<Map<String, dynamic>> _handleAnalyticsImpression(BridgeMessage msg) async {
    final params = msg.getMapOrNull('params');
    debugPrint('[Bridge] Analytics Impression (not implemented): $params');
    return {'success': true};
  }

  /// Opens the Game Center leaderboard (stub implementation).
  Future<Map<String, dynamic>> _handleGameCenterOpenLeaderboard() async {
    debugPrint('[Bridge] Game Center Open Leaderboard (not implemented)');
    return {'success': false};
  }

  /// Submits a score to Game Center (stub implementation).
  Future<Map<String, dynamic>> _handleGameCenterSubmitScore(BridgeMessage msg) async {
    final score = msg.getStringOrNull('score');
    debugPrint('[Bridge] Game Center Submit Score (not implemented): $score');
    return {'success': false, 'submitted': false};
  }

  /// Pauses the game in the WebView (before ads or app backgrounding).
  Future<void> pauseGame() async {
    try {
      await webViewController.runJavaScript('''
        if (window.__GAME_PAUSE__) {
          window.__GAME_PAUSE__();
          console.log('[Flutter] Game paused for ad');
        } else if (window.__PIXI_APP__ && window.__PIXI_APP__.ticker) {
          window.__PIXI_APP__.ticker.stop();
          console.log('[Flutter] Game paused (fallback) for ad');
        }
      ''');
    } catch (e) {
      debugPrint('[Bridge] Failed to pause game: $e');
    }
  }

  /// Resumes the game in the WebView (after ads or app foregrounding).
  Future<void> resumeGame() async {
    try {
      await webViewController.runJavaScript('''
        if (window.__GAME_RESUME__) {
          window.__GAME_RESUME__();
          console.log('[Flutter] Game resumed after ad');
        } else if (window.__PIXI_APP__ && window.__PIXI_APP__.ticker) {
          window.__PIXI_APP__.ticker.start();
          console.log('[Flutter] Game resumed (fallback) after ad');
        }
      ''');
    } catch (e) {
      debugPrint('[Bridge] Failed to resume game: $e');
    }
  }

  /// Sends a [BridgeResponse] back to the WebView via CustomEvent.
  Future<void> _sendResponse(BridgeResponse response) async {
    final resultJson = jsonEncode(response.toJson());
    final jsStringLiteral = jsonEncode(resultJson);
    final js =
        'window.dispatchEvent(new CustomEvent(\'flutterBridgeResult\', { detail: JSON.parse($jsStringLiteral) }));';

    await webViewController.runJavaScript(js);
    debugPrint('[Bridge] Result sent: ${response.type} (success: ${response.success})');
  }
}
