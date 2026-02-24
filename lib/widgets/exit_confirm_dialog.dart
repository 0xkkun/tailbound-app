import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../ad_manager.dart';
import '../l10n/app_localizations.dart';

class ExitConfirmDialog extends StatefulWidget {
  const ExitConfirmDialog({super.key});

  @override
  State<ExitConfirmDialog> createState() => _ExitConfirmDialogState();
}

class _ExitConfirmDialogState extends State<ExitConfirmDialog> {
  BannerAd? _bannerAd;
  bool _bannerReady = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdManager.getBannerAdUnitId(BannerAdType.exitPopup),
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Exit banner ad loaded');
          if (mounted) setState(() => _bannerReady = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Exit banner ad failed to load: $error');
          ad.dispose();
          _bannerAd = null;
          _retryCount++;
          if (_retryCount < _maxRetries) {
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) _loadBannerAd();
            });
          }
        },
      ),
    );
    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_bannerReady && _bannerAd != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: AdSize.mediumRectangle.width.toDouble(),
                  height: AdSize.mediumRectangle.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
              ),
            if (_bannerReady && _bannerAd != null) const SizedBox(height: 16),
            Text(
              l10n.exitDialogTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.exitDialogSubtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      l10n.exitDialogCancel,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B0000),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      l10n.exitDialogConfirm,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
