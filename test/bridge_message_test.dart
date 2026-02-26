import 'package:flutter_test/flutter_test.dart';
import 'package:tailbound_app/models/bridge_message.dart';

void main() {
  group('BridgeMessage', () {
    test('parses valid JSON correctly', () {
      final json = {
        'id': 'msg-1',
        'type': 'storage.get',
        'payload': {'key': 'theme'},
      };

      final msg = BridgeMessage.fromJson(json);
      expect(msg.id, 'msg-1');
      expect(msg.type, 'storage.get');
      expect(msg.getString('key'), 'theme');
    });

    test('throws FormatException when id is missing', () {
      final json = {
        'type': 'storage.get',
        'payload': <String, dynamic>{},
      };
      expect(() => BridgeMessage.fromJson(json), throwsFormatException);
    });

    test('throws FormatException when type is missing', () {
      final json = {
        'id': 'msg-1',
        'payload': <String, dynamic>{},
      };
      expect(() => BridgeMessage.fromJson(json), throwsFormatException);
    });

    test('throws FormatException when payload is not a map', () {
      final json = {
        'id': 'msg-1',
        'type': 'test',
        'payload': 'not-a-map',
      };
      expect(() => BridgeMessage.fromJson(json), throwsFormatException);
    });

    test('getString returns default when key missing', () {
      final msg = BridgeMessage.fromJson({
        'id': '1',
        'type': 'test',
        'payload': <String, dynamic>{},
      });
      expect(msg.getString('missing', defaultValue: 'fallback'), 'fallback');
    });

    test('getStringOrNull returns null when key missing', () {
      final msg = BridgeMessage.fromJson({
        'id': '1',
        'type': 'test',
        'payload': <String, dynamic>{},
      });
      expect(msg.getStringOrNull('missing'), isNull);
    });

    test('getIntOrNull parses string int', () {
      final msg = BridgeMessage.fromJson({
        'id': '1',
        'type': 'test',
        'payload': {'score': '42'},
      });
      expect(msg.getIntOrNull('score'), 42);
    });

    test('getIntOrNull returns int directly', () {
      final msg = BridgeMessage.fromJson({
        'id': '1',
        'type': 'test',
        'payload': {'score': 99},
      });
      expect(msg.getIntOrNull('score'), 99);
    });

    test('getMapOrNull returns null for non-map', () {
      final msg = BridgeMessage.fromJson({
        'id': '1',
        'type': 'test',
        'payload': {'params': 'not-a-map'},
      });
      expect(msg.getMapOrNull('params'), isNull);
    });

    test('toString returns readable format', () {
      final msg = BridgeMessage.fromJson({
        'id': 'abc',
        'type': 'haptic.impact',
        'payload': <String, dynamic>{},
      });
      expect(msg.toString(), 'BridgeMessage(id: abc, type: haptic.impact)');
    });
  });

  group('BridgeResponse', () {
    test('success factory creates correct response', () {
      final resp = BridgeResponse.success('1', 'test', data: {'ok': true});
      expect(resp.success, isTrue);
      expect(resp.error, isNull);
      expect(resp.data, {'ok': true});
    });

    test('failure factory creates correct response', () {
      final resp = BridgeResponse.failure('1', 'test', 'something broke');
      expect(resp.success, isFalse);
      expect(resp.error, 'something broke');
      expect(resp.data, isNull);
    });

    test('toJson includes all fields', () {
      final resp = BridgeResponse.success('id-1', 'type-1');
      final json = resp.toJson();
      expect(json['id'], 'id-1');
      expect(json['type'], 'type-1');
      expect(json['success'], isTrue);
      expect(json.containsKey('timestamp'), isTrue);
    });
  });
}
