import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/permission_gate.dart';
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
      home: PermissionGate(
        settings: settings,
        entitlements: entitlements,
        billing: billing,
        library: library,
      ),
    );
  }
}
