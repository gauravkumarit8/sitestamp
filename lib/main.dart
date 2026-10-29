import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/permission_gate.dart';
import 'services/app_settings.dart';
import 'services/entitlements.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // MVP: portrait only. Avoids the orientation bugs seen in competing apps.
  await SystemChrome.setPreferredOrientations(
    const [DeviceOrientation.portraitUp],
  );
  final settings = await AppSettings.load();
  final entitlements = await Entitlements.load();
  runApp(SiteStampApp(settings: settings, entitlements: entitlements));
}

class SiteStampApp extends StatelessWidget {
  const SiteStampApp({
    super.key,
    required this.settings,
    required this.entitlements,
  });

  final AppSettings settings;
  final Entitlements entitlements;

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
      home: PermissionGate(settings: settings, entitlements: entitlements),
    );
  }
}
