import 'package:flutter_test/flutter_test.dart';
import 'package:tailbound_app/services/preferences_service.dart';

void main() {
  group('PreferencesService', () {
    setUp(() {
      // Reset cached instance before each test
      PreferencesService.resetForTesting();
    });

    test('instance throws StateError before init', () {
      expect(
        () => PreferencesService.instance,
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('PreferencesService.init()'),
          ),
        ),
      );
    });
  });
}
