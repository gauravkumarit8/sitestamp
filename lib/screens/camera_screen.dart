import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:geolocator/geolocator.dart';

import '../services/address_service.dart';
import '../services/app_settings.dart';
import '../services/entitlements.dart';
import '../services/location_service.dart';
import '../services/stamp_service.dart';
import '../widgets/gps_status_pill.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({
    super.key,
    required this.settings,
    required this.entitlements,
  });

  final AppSettings settings;
  final Entitlements entitlements;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  final LocationService _location = LocationService();
  final AddressService _address = AddressService();
  final TextEditingController _memo = TextEditingController();

  List<CameraDescription> _cameras = const [];
  CameraController? _controller;
  int _cameraIndex = 0;
  FlashMode _flash = FlashMode.auto;
  bool _initializing = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _location.latest.addListener(_onFix);
    _location.start(); // pre-warm GPS immediately
    _initCamera();
  }

  bool get _addressEnabled =>
      widget.settings.showAddress && widget.entitlements.canShowAddress;

  void _onFix() {
    final p = _location.latest.value;
    if (p != null && _addressEnabled) {
      _address.update(p); // background lookup, never blocks capture
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _location.latest.removeListener(_onFix);
    _address.dispose();
    _location.dispose();
    _memo.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      final c = _controller;
      if (c != null && !_saving) {
        _controller = null;
        if (mounted) setState(() {});
        c.dispose();
      }
      _location.stop();
    } else if (state == AppLifecycleState.resumed) {
      _location.restart();
      if (_controller == null && !_initializing) _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (_initializing) return;
    _initializing = true;
    try {
      if (_cameras.isEmpty) {
        _cameras = await availableCameras();
        final back = _cameras.indexWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
        );
        _cameraIndex = back >= 0 ? back : 0;
      }
      if (_cameras.isEmpty) {
        _setError('No camera found on this device.');
        return;
      }
      final c = CameraController(
        _cameras[_cameraIndex],
        ResolutionPreset.high, // avoids RAM spikes on budget devices
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await c.initialize();
      await c.lockCaptureOrientation(DeviceOrientation.portraitUp);
      try {
        await c.setFlashMode(_flash);
      } catch (_) {} // front cameras often have no flash
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _controller = c;
        _error = null;
      });
    } on CameraException catch (e) {
      _setError('Camera error: ${e.description ?? e.code}');
    } catch (e) {
      _setError('Camera error: $e');
    } finally {
      _initializing = false;
    }
  }

  void _setError(String msg) {
    if (mounted) setState(() => _error = msg);
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _saving || _initializing) return;
    final current = _cameras[_cameraIndex].lensDirection;
    final target = current == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    final idx = _cameras.indexWhere((c) => c.lensDirection == target);
    if (idx < 0) return;

    final old = _controller;
    setState(() {
      _controller = null;
      _cameraIndex = idx;
    });
    await old?.dispose();
    await _initCamera();
  }

  Future<void> _cycleFlash() async {
    final next = switch (_flash) {
      FlashMode.auto => FlashMode.always,
      FlashMode.always => FlashMode.off,
      _ => FlashMode.auto,
    };
    setState(() => _flash = next);
    try {
      await _controller?.setFlashMode(next);
    } catch (_) {}
  }

  IconData get _flashIcon => switch (_flash) {
        FlashMode.always => Icons.flash_on,
        FlashMode.off => Icons.flash_off,
        _ => Icons.flash_auto,
      };

  Future<void> _capture() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || c.value.isTakingPicture) return;
    if (_saving) return;
    setState(() => _saving = true);

    try {
      // Make sure we can save BEFORE taking the picture.
      final ok = await Gal.hasAccess(toAlbum: true) ||
          await Gal.requestAccess(toAlbum: true);
      if (!ok) {
        _toast('Photo library access is needed to save pictures.');
        return;
      }

      // Snapshot GPS + time at the moment of the tap.
      final fix = _location.freshFix();
      final data = _location.snapshot(
        branding: widget.entitlements.showBranding,
        time: DateTime.now(),
        memo: _memo.text.trim(),
        address: (_addressEnabled && fix != null)
            ? _address.addressFor(fix)
            : null,
      );

      final shot = await c.takePicture();
      await StampService.stampAndSave(rawPath: shot.path, data: data);
      await widget.settings.addRecentMemo(data.memo);
      _toast(data.hasFix
          ? 'Saved to gallery'
          : 'Saved (no GPS fix - location not stamped)');
    } catch (e) {
      _toast('Could not save photo: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _onPillTap() async {
    if (!_location.serviceEnabled.value) {
      await Geolocator.openLocationSettings();
    }
    await _location.restart();
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(child: _buildPreview()),
          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: GpsStatusPill(
                        location: _location,
                        onTap: _onPillTap,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _RoundButton(icon: _flashIcon, onTap: _cycleFlash),
                  const SizedBox(width: 8),
                  _RoundButton(
                    icon: Icons.cameraswitch_outlined,
                    onTap: _switchCamera,
                  ),
                  const SizedBox(width: 8),
                  _RoundButton(icon: Icons.tune, onTap: _openSettings),
                ],
              ),
            ),
          ),
          // Bottom controls
          Positioned(
            left: 0,
            right: 0,
            bottom: keyboard,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMemoChips(),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _memo,
                      builder: (context, value, _) => TextField(
                        controller: _memo,
                        maxLength: 120,
                        maxLines: 2,
                        minLines: 1,
                        textInputAction: TextInputAction.done,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Custom note / memo (optional)',
                          counterText: '',
                          filled: true,
                          fillColor: const Color(0x99000000),
                          suffixIcon: value.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: _memo.clear,
                                ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ShutterButton(busy: _saving, onTap: _capture),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoChips() {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.settings, widget.entitlements]),
      builder: (context, _) {
        final recents =
            widget.settings.recentMemos.take(widget.entitlements.maxRecentMemos).toList();
        final all = <String>[
          ...recents,
          ...AppSettings.defaultPresets.where((p) => !recents.contains(p)),
        ];
        return SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: all.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final text = all[index];
              final isRecent = recents.contains(text);
              return InputChip(
                label: Text(text),
                labelStyle: const TextStyle(color: Colors.white),
                backgroundColor: const Color(0x99000000),
                onPressed: () {
                  _memo.value = TextEditingValue(
                    text: text,
                    selection: TextSelection.collapsed(offset: text.length),
                  );
                },
                onDeleted:
                    isRecent ? () => widget.settings.removeRecentMemo(text) : null,
              );
            },
          ),
        );
      },
    );
  }

  void _openSettings() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: AnimatedBuilder(
            animation: Listenable.merge([widget.settings, widget.entitlements]),
            builder: (ctx, _) {
              final pro = widget.entitlements.isPro;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    secondary: pro ? null : const Icon(Icons.lock_outline),
                    title: const Text('Show address on photo'),
                    subtitle: Text(
                      pro
                          ? 'Looks up the street address (needs internet). '
                              'Photos are still stamped with GPS if it fails.'
                          : 'Pro feature.',
                    ),
                    value: pro && widget.settings.showAddress,
                    onChanged: pro
                        ? (v) => widget.settings.setShowAddress(v)
                        : null,
                  ),
                  ListTile(
                    leading: Icon(pro ? Icons.verified : Icons.workspace_premium),
                    title: Text(pro ? 'SiteStamp Pro' : 'SiteStamp Pro (coming soon)'),
                    subtitle: Text(
                      pro
                          ? 'No branding, address on photos, 10 saved notes.'
                          : 'Remove the "Made with SiteStamp" line, add the '
                              'street address, and keep 10 saved notes.',
                    ),
                  ),
                  if (kDebugMode)
                    SwitchListTile(
                      title: const Text('Pro (testing only)'),
                      subtitle: const Text('Only visible in debug builds.'),
                      value: pro,
                      onChanged: (v) => widget.entitlements.setDebugPro(v),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    final ps = c.value.previewSize;
    if (ps == null) return CameraPreview(c);
    // previewSize is reported in landscape; we are portrait-locked.
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: ps.height,
          height: ps.width,
          child: CameraPreview(c),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x99000000),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.busy, required this.onTap});
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        width: 76,
        height: 76,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: busy ? Colors.grey : Colors.white,
          ),
          child: busy
              ? const Padding(
                  padding: EdgeInsets.all(18),
                  child: CircularProgressIndicator(strokeWidth: 3),
                )
              : null,
        ),
      ),
    );
  }
}
