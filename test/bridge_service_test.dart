import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:tailbound_app/models/bridge_message.dart';

void main() {
  group('BridgeService message routing', () {
    test('valid JSON with all fields parses correctly', () {
      const raw = '{"id":"1","type":"storage.get","payload":{"key":"test"}}';
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final msg = BridgeMessage.fromJson(json);

      expect(msg.id, '1');
      expect(msg.type, 'storage.get');
      expect(msg.getString('key'), 'test');
    });

    test('invalid JSON string is caught', () {
      const raw = 'not-json-at-all';
      expect(() => jsonDecode(raw), throwsFormatException);
    });

    test('valid JSON but not an object', () {
      const raw = '"just a string"';
      final decoded = jsonDecode(raw);
      expect(decoded is Map<String, dynamic>, isFalse);
    });

    test('missing payload field throws FormatException', () {
      const raw = '{"id":"1","type":"test"}';
      final json = jsonDecode(raw) as Map<String, dynamic>;
      expect(() => BridgeMessage.fromJson(json), throwsFormatException);
    });

    test('all known message types are valid strings', () {
      const knownTypes = [
        'ad.request',
        'ad.preload',
        'safeArea.get',
        'storage.set',
        'storage.get',
        'storage.remove',
        'haptic.impact',
        'share.open',
        'analytics.click',
        'analytics.impression',
        'gameCenter.openLeaderboard',
        'gameCenter.submitScore',
      ];

      for (final type in knownTypes) {
        final msg = BridgeMessage.fromJson({
          'id': 'test',
          'type': type,
          'payload': <String, dynamic>{},
        });
        expect(msg.type, type);
      }
    });
  });

  group('BridgeService ad type parsing', () {
    test('storage.set message extracts key and value', () {
      final msg = BridgeMessage.fromJson({
        'id': '1',
        'type': 'storage.set',
        'payload': {'key': 'settings', 'value': '{"dark":true}'},
      });
      expect(msg.getString('key'), 'settings');
      expect(msg.getString('value'), '{"dark":true}');
    });

    test('haptic message with missing style uses default', () {
      final msg = BridgeMessage.fromJson({
        'id': '1',
        'type': 'haptic.impact',
        'payload': <String, dynamic>{},
      });
      expect(
        msg.getString('style', defaultValue: 'mediumImpact'),
        'mediumImpact',
      );
    });

    test('share message extracts url and optional title', () {
      final msg = BridgeMessage.fromJson({
        'id': '1',
        'type': 'share.open',
        'payload': {'url': 'https://example.com', 'title': 'Check this'},
      });
      expect(msg.getString('url'), 'https://example.com');
      expect(msg.getStringOrNull('title'), 'Check this');
    });
  });
}
