import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/app_settings.dart';
import '../services/billing_service.dart';
import '../services/entitlements.dart';
import '../services/photo_library.dart';
import 'camera_screen.dart';

class PermissionGate extends StatefulWidget {
  const PermissionGate({
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
  State<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends State<PermissionGate>
    with WidgetsBindingObserver {
  bool _checking = true;
  bool _granted = false;
  bool _permanentlyDenied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check(request: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // User may come back from system settings.
    if (state == AppLifecycleState.resumed && !_granted) {
      _check(request: false);
    }
  }

  Future<void> _check({required bool request}) async {
    var cam = await Permission.camera.status;
    var loc = await Permission.locationWhenInUse.status;

    if (request) {
      if (!cam.isGranted && !cam.isPermanentlyDenied) {
        cam = await Permission.camera.request();
      }
      if (!loc.isGranted && !loc.isPermanentlyDenied) {
        loc = await Permission.locationWhenInUse.request();
      }
    }

    if (!mounted) return;
    setState(() {
      _checking = false;
      _granted = cam.isGranted && loc.isGranted;
      _permanentlyDenied = cam.isPermanentlyDenied || loc.isPermanentlyDenied;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_granted) {
      return CameraScreen(
        settings: widget.settings,
        entitlements: widget.entitlements,
        billing: widget.billing,
        library: widget.library,
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.photo_camera_outlined, size: 64),
              const SizedBox(height: 16),
              Text(
                'SiteStamp needs two permissions',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'Camera: to take the photo.\n'
                'Location: to stamp where it was taken.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_permanentlyDenied)
                FilledButton(
                  onPressed: openAppSettings,
                  child: const Text('Open Settings'),
                )
              else
                FilledButton(
                  onPressed: () => _check(request: true),
                  child: const Text('Grant permissions'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
