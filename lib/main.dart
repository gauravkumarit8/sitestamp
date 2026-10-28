import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/permission_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // MVP: portrait only. Avoids the orientation bugs seen in competing apps.
  await SystemChrome.setPreferredOrientations(
    const [DeviceOrientation.portraitUp],
  );
  runApp(const SiteStampApp());
}

class SiteStampApp extends StatelessWidget {
  const SiteStampApp({super.key});

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
      home: const PermissionGate(),
    );
  }
}
