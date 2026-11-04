import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/onboarding_screen.dart';
import 'screens/permission_gate.dart';
import 'services/ads_service.dart';
import 'services/app_settings.dart';
import 'services/billing_service.dart';
import 'services/entitlements.dart';
import 'services/photo_library.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // MVP: portrait only. Avoids the orientation bugs seen in competing apps.
  await SystemChrome.setPreferredOrientations(
    const [DeviceOrientation.portraitUp],
  );
  final settings = await AppSettings.load();
  final entitlements = await Entitlements.load();
  final billing = BillingService(entitlements);
  unawaited(billing.init()); // do not delay app start
  if (entitlements.showAds) {
    // After the first frames, so the consent form can show over the UI.
    unawaited(
      Future<void>.delayed(const Duration(seconds: 2), AdsService.instance.init),
    );
  }
  runApp(
    SiteStampApp(
      settings: settings,
      entitlements: entitlements,
      billing: billing,
      library: PhotoLibrary(),
    ),
  );
}

class SiteStampApp extends StatelessWidget {
  const SiteStampApp({
    super.key,
    required this.settings,
    required this.entitlements,
    required this.billing,
    required this.library,
  });

  final AppSettings settings;
  final Entitlements entitlements;
  final BillingService billing;
  final PhotoLibrary library;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SiteStamp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFFFF8F00),
        useMaterial3: true,
      ),
      home: _Root(
        settings: settings,
        entitlements: entitlements,
        billing: billing,
        library: library,
      ),
    );
  }
}

/// Shows the welcome screens once, then the normal app.
class _Root extends StatefulWidget {
  const _Root({
    required this.settings,
    required this.entitlements,
    required this.billing,
    required this.library,
  });

  final AppSettings settings;
  final Entitlements entitlements;
  final BillingService billing;
  final PhotoLibrary library;

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  late bool _onboarded = widget.settings.onboardingDone;

  @override
  Widget build(BuildContext context) {
    if (!_onboarded) {
      return OnboardingScreen(
        settings: widget.settings,
        onDone: () async {
          await widget.settings.setOnboardingDone();
          if (mounted) setState(() => _onboarded = true);
        },
      );
    }
    return PermissionGate(
      settings: widget.settings,
      entitlements: widget.entitlements,
      billing: widget.billing,
      library: widget.library,
    );
  }
}
