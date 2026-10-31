import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config.dart';

/// Google AdMob wrapper: consent (UMP), banner support and a rewarded ad.
/// Singleton so screens do not need it passed around.
class AdsService extends ChangeNotifier {
  AdsService._();
  static final AdsService instance = AdsService._();

  bool _initialized = false;
  bool _initializing = false;
  RewardedAd? _rewarded;
  bool _loadingRewarded = false;

  /// True once the Mobile Ads SDK is initialised (after consent, if required).
  bool get ready => _initialized;
  bool get rewardedAvailable => _rewarded != null;

  Future<void> init() async {
    if (!kAdsEnabled || _initialized || _initializing) return;
    _initializing = true;
    try {
      // 1) Ask for consent where required (EEA/UK). Needs a message published
      //    in AdMob > Privacy & messaging; otherwise no form is shown.
      final consentDone = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () {
          ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
            if (!consentDone.isCompleted) consentDone.complete();
          });
        },
        (FormError error) {
          if (!consentDone.isCompleted) consentDone.complete();
        },
      );
      await consentDone.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () {},
      );

      // 2) Start the SDK only if we are allowed to request ads.
      if (await ConsentInformation.instance.canRequestAds()) {
        await MobileAds.instance.initialize();
        _initialized = true;
        notifyListeners();
        loadRewarded();
      }
    } catch (_) {
      // Ads are optional; never break the app because of them.
    } finally {
      _initializing = false;
    }
  }

  void loadRewarded() {
    if (!_initialized || _rewarded != null || _loadingRewarded) return;
    _loadingRewarded = true;
    RewardedAd.load(
      adUnitId: kAdMobRewardedUnitId,
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _loadingRewarded = false;
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          _loadingRewarded = false;
        },
      ),
    );
  }

  /// Shows the rewarded ad; true only if the user earned the reward.
  Future<bool> showRewarded() async {
    final ad = _rewarded;
    if (ad == null) {
      loadRewarded();
      return false;
    }
    _rewarded = null;
    notifyListeners();
    final done = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (shown) {
        shown.dispose();
        loadRewarded();
        if (!done.isCompleted) done.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (shown, error) {
        shown.dispose();
        loadRewarded();
        if (!done.isCompleted) done.complete(false);
      },
    );
    ad.show(
      onUserEarnedReward: (view, reward) {
        earned = true;
      },
    );
    return done.future;
  }
}
