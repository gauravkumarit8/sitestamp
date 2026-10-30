import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../config.dart';
import 'entitlements.dart';

enum BillingStatus { loading, ready, unavailable }

/// Thin wrapper around Google Play Billing (client-side checks only).
class BillingService extends ChangeNotifier {
  BillingService(this._entitlements);

  final Entitlements _entitlements;
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  BillingStatus status = BillingStatus.loading;
  List<ProductDetails> products = const [];
  String? message;
  bool busy = false;

  Future<void> init() async {
    _sub ??= _iap.purchaseStream.listen(
      _onPurchases,
      onError: (Object e) {
        busy = false;
        message = 'Purchase error. Please try again.';
        notifyListeners();
      },
    );
    try {
      final available = await _iap.isAvailable();
      if (!available) {
        status = BillingStatus.unavailable;
        notifyListeners();
        return;
      }
      final resp = await _iap.queryProductDetails(kProProductOrder.toSet());
      final list = resp.productDetails.toList()
        ..sort(
          (a, b) => kProProductOrder
              .indexOf(a.id)
              .compareTo(kProProductOrder.indexOf(b.id)),
        );
      products = list;
      status = list.isEmpty ? BillingStatus.unavailable : BillingStatus.ready;
      notifyListeners();
      // Re-confirm any existing purchase (also refreshes the offline grace).
      await _iap.restorePurchases();
    } catch (_) {
      status = BillingStatus.unavailable;
      notifyListeners();
    }
  }

  Future<void> buy(ProductDetails details) async {
    if (busy) return;
    busy = true;
    message = null;
    notifyListeners();
    try {
      final started = await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: details),
      );
      if (!started) {
        busy = false;
        message = 'Could not start the purchase.';
        notifyListeners();
      }
    } catch (_) {
      busy = false;
      message = 'Could not start the purchase.';
      notifyListeners();
    }
  }

  Future<void> restore() async {
    message = 'Checking purchases...';
    notifyListeners();
    try {
      await _iap.restorePurchases();
    } catch (_) {
      message = 'Could not check purchases.';
      notifyListeners();
      return;
    }
    Future<void>.delayed(const Duration(seconds: 6), () {
      if (message == 'Checking purchases...') {
        message = 'No active purchase found for this Google account.';
        notifyListeners();
      }
    });
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (kProProductOrder.contains(p.productID)) {
        switch (p.status) {
          case PurchaseStatus.pending:
            busy = true;
            message = 'Payment pending...';
          case PurchaseStatus.purchased:
            busy = false;
            message = 'Thank you! Pro is unlocked.';
            await _entitlements.applyPurchase(pro: true);
          case PurchaseStatus.restored:
            busy = false;
            message = 'Purchase restored. Pro is unlocked.';
            await _entitlements.applyPurchase(pro: true);
          case PurchaseStatus.error:
            busy = false;
            message = p.error?.message ?? 'Purchase failed.';
          case PurchaseStatus.canceled:
            busy = false;
            message = 'Purchase cancelled.';
        }
      }
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
