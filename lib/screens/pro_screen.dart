import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../config.dart';
import '../services/billing_service.dart';
import '../services/entitlements.dart';

class ProScreen extends StatelessWidget {
  const ProScreen({
    super.key,
    required this.billing,
    required this.entitlements,
  });

  final BillingService billing;
  final Entitlements entitlements;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SiteStamp Pro')),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([billing, entitlements]),
          builder: (context, _) {
            final owned = entitlements.isPurchasedPro;
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Icon(Icons.workspace_premium, size: 56),
                const SizedBox(height: 12),
                Text(
                  owned ? 'You have SiteStamp Pro' : 'Upgrade to SiteStamp Pro',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                const _Benefit('No ads anywhere in the app'),
                const _Benefit('No "Made with SiteStamp" line on photos'),
                const _Benefit('Your company, job no. and inspector on every photo'),
                const _Benefit('Stamp themes, position and size'),
                const _Benefit('Projects: one gallery album per job'),
                const _Benefit('Before / After comparison images'),
                const _Benefit('Unlimited PDF and CSV export'),
                const _Benefit('Keep every photo in the in-app list'),
                const SizedBox(height: 20),
                if (!owned) ..._buildProducts(context),
                if (billing.message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      billing.message!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: billing.restore,
                  child: const Text('Restore purchases'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The yearly plan renews automatically each year until you '
                  'cancel it in Google Play. The lifetime option is a '
                  'one-time purchase. Payments are handled by Google Play.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildProducts(BuildContext context) {
    switch (billing.status) {
      case BillingStatus.loading:
        return const [Center(child: CircularProgressIndicator())];
      case BillingStatus.unavailable:
        return const [
          Text(
            'Purchases are not available right now. Install the app from '
            'Google Play and try again later.',
            textAlign: TextAlign.center,
          ),
        ];
      case BillingStatus.ready:
        return [for (final p in billing.products) _productCard(p)];
    }
  }

  Widget _productCard(ProductDetails p) {
    final yearly = p.id == kProYearlyId;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    yearly ? 'Pro yearly' : 'Pro lifetime',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(yearly ? '${p.price} per year' : '${p.price} one time'),
                ],
              ),
            ),
            FilledButton(
              onPressed: billing.busy ? null : () => billing.buy(p),
              child: Text(yearly ? 'Subscribe' : 'Buy'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF43A047), size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
