import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cached wrapper around [SharedPreferences] to avoid repeated async lookups.
///
/// Call [PreferencesService.init] once at app startup, then use the
/// synchronous [instance] getter throughout the app.
class PreferencesService {
  static SharedPreferences? _instance;

  /// Resets the cached instance (for testing only).
  @visibleForTesting
  static void resetForTesting() {
    _instance = null;
  }

  /// Initializes and caches the [SharedPreferences] instance.
  ///
  /// Must be called once before accessing [instance].
  static Future<void> init() async {
    _instance ??= await SharedPreferences.getInstance();
  }

  /// Returns the cached [SharedPreferences] instance.
  ///
  /// Throws [StateError] if [init] has not been called.
  static SharedPreferences get instance {
    final prefs = _instance;
    if (prefs == null) {
      throw StateError(
        'PreferencesService.init() must be called before accessing instance',
      );
    }
    return prefs;
  }
}
