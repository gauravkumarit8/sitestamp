import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config.dart';
import '../services/ads_service.dart';
import '../services/entitlements.dart';

/// Small banner for free users. Collapses to nothing for Pro users, when ads
/// are disabled, or while no ad is loaded.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key, required this.entitlements});

  final Entitlements entitlements;

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    AdsService.instance.addListener(_maybeLoad);
    widget.entitlements.addListener(_onEntitlements);
    _maybeLoad();
  }

  @override
  void dispose() {
    AdsService.instance.removeListener(_maybeLoad);
    widget.entitlements.removeListener(_onEntitlements);
    _ad?.dispose();
    super.dispose();
  }

  void _onEntitlements() {
    if (widget.entitlements.isPro) {
      _ad?.dispose();
      _ad = null;
      _loaded = false;
    } else {
      _maybeLoad();
    }
    if (mounted) setState(() {});
  }

  void _maybeLoad() {
    if (!kAdsEnabled ||
        widget.entitlements.isPro ||
        !AdsService.instance.ready ||
        _ad != null) {
      return;
    }
    final ad = BannerAd(
      adUnitId: kAdMobBannerUnitId,
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (failed, error) {
          failed.dispose();
          if (mounted) {
            setState(() {
              _ad = null;
              _loaded = false;
            });
          }
        },
      ),
    );
    _ad = ad;
    ad.load();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!kAdsEnabled || widget.entitlements.isPro || ad == null || !_loaded) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
