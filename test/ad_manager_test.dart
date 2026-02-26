import 'package:flutter_test/flutter_test.dart';
import 'package:tailbound_app/ad_manager.dart';

void main() {
  group('AdManager.parseRewardAdType', () {
    test('parses "artifact" correctly', () {
      expect(AdManager.parseRewardAdType('artifact'), RewardAdType.artifact);
    });

    test('parses "revival" correctly', () {
      expect(AdManager.parseRewardAdType('revival'), RewardAdType.revival);
    });

    test('parses "reroll" correctly', () {
      expect(AdManager.parseRewardAdType('reroll'), RewardAdType.reroll);
    });

    test('parses "bundle" correctly', () {
      expect(AdManager.parseRewardAdType('bundle'), RewardAdType.bundle);
    });

    test('is case insensitive', () {
      expect(AdManager.parseRewardAdType('ARTIFACT'), RewardAdType.artifact);
      expect(AdManager.parseRewardAdType('Revival'), RewardAdType.revival);
    });

    test('returns null for unknown type', () {
      expect(AdManager.parseRewardAdType('unknown'), isNull);
      expect(AdManager.parseRewardAdType(''), isNull);
    });
  });

  group('AdManager singleton', () {
    test('returns same instance', () {
      final a = AdManager();
      final b = AdManager();
      expect(identical(a, b), isTrue);
    });

    test('isAdReady returns false when no ad loaded', () {
      expect(AdManager().isAdReady(RewardAdType.artifact), isFalse);
      expect(AdManager().isAdReady(RewardAdType.revival), isFalse);
    });

    test('isInterstitialAdReady returns false when no ad loaded', () {
      expect(
        AdManager().isInterstitialAdReady(InterstitialAdType.gameInterstitial),
        isFalse,
      );
    });
  });

  group('AdManager enum coverage', () {
    test('RewardAdType has 4 values', () {
      expect(RewardAdType.values.length, 4);
    });

    test('InterstitialAdType has 1 value', () {
      expect(InterstitialAdType.values.length, 1);
    });

    test('BannerAdType has 1 value', () {
      expect(BannerAdType.values.length, 1);
    });
  });
}
