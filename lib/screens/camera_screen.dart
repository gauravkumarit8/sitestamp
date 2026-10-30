import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../models/stamp_data.dart';
import '../models/stamp_style.dart';
import '../services/address_service.dart';
import '../services/app_settings.dart';
import '../services/billing_service.dart';
import '../services/entitlements.dart';
import '../services/location_service.dart';
import '../services/stamp_service.dart';
import '../widgets/gps_status_pill.dart';
import 'pro_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({
    super.key,
    required this.settings,
    required this.entitlements,
    required this.billing,
  });

  final AppSettings settings;
  final Entitlements entitlements;
  final BillingService billing;

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

  // zoom / focus / shutter feedback
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _zoom = 1.0;
  double _baseZoom = 1.0;
  Offset? _focusPoint;
  Timer? _focusTimer;
  bool _shutterFlash = false;

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
    _focusTimer?.cancel();
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
      try {
        _minZoom = await c.getMinZoomLevel();
        _maxZoom = await c.getMaxZoomLevel();
        // Cap pinch zoom: very high digital zoom makes poor proof photos.
        if (_maxZoom > 8.0) _maxZoom = 8.0;
        _zoom = _minZoom;
      } catch (_) {
        _minZoom = _maxZoom = _zoom = 1.0;
      }
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

  Future<void> _focusAt(Offset p, Size size) async {
    FocusScope.of(context).unfocus(); // dismiss keyboard on preview tap
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final point = Offset(
      (p.dx / size.width).clamp(0.0, 1.0).toDouble(),
      (p.dy / size.height).clamp(0.0, 1.0).toDouble(),
    );
    setState(() => _focusPoint = p);
    _focusTimer?.cancel();
    _focusTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _focusPoint = null);
    });
    try {
      await c.setFocusPoint(point);
      await c.setExposurePoint(point);
    } catch (_) {} // not supported on every camera
  }

  Future<void> _setZoom(double z) async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final clamped = z.clamp(_minZoom, _maxZoom).toDouble();
    if ((clamped - _zoom).abs() < 0.01) return;
    setState(() => _zoom = clamped);
    try {
      await c.setZoomLevel(clamped);
    } catch (_) {}
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
    setState(() {
      _saving = true;
      _shutterFlash = true;
    });
    HapticFeedback.mediumImpact();
    Future<void>.delayed(const Duration(milliseconds: 140), () {
      if (mounted) setState(() => _shutterFlash = false);
    });

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
        project: widget.entitlements.canUseProjects ? widget.settings.project : '',
        time: DateTime.now(),
        memo: _memo.text.trim(),
        address: (_addressEnabled && fix != null)
            ? _address.addressFor(fix)
            : null,
      );

      final shot = await c.takePicture();
      await StampService.stampAndSave(
        rawPath: shot.path,
        data: data,
        style: widget.entitlements.canCustomizeStamp
            ? widget.settings.stampStyle
            : const StampStyle(),
      );
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
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => _focusAt(d.localPosition, constraints.biggest),
                onScaleStart: (_) => _baseZoom = _zoom,
                onScaleUpdate: (d) {
                  if (d.pointerCount >= 2) _setZoom(_baseZoom * d.scale);
                },
                child: _buildPreview(),
              ),
            ),
          ),
          // Rule-of-thirds grid (optional)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: widget.settings,
                builder: (context, _) => widget.settings.showGrid
                    ? CustomPaint(painter: _GridPainter())
                    : const SizedBox.shrink(),
              ),
            ),
          ),
          // Focus ring
          if (_focusPoint != null)
            Positioned(
              left: _focusPoint!.dx - 32,
              top: _focusPoint!.dy - 32,
              child: IgnorePointer(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFFCA28), width: 2),
                  ),
                ),
              ),
            ),
          // Shutter flash
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _shutterFlash ? 0.55 : 0.0,
                duration: const Duration(milliseconds: 90),
                child: const ColoredBox(color: Colors.white),
              ),
            ),
          ),
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
                    if (_zoom - _minZoom > 0.05)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x99000000),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          '${(_zoom / _minZoom).toStringAsFixed(1)}x',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    _buildProjectChip(),
                    const SizedBox(height: 6),
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

  Widget _buildProjectChip() {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.settings, widget.entitlements]),
      builder: (context, _) {
        final pro = widget.entitlements.canUseProjects;
        final name = widget.settings.project;
        final label = (pro && name.isNotEmpty) ? name : 'SiteStamp album';
        return Align(
          alignment: Alignment.centerLeft,
          child: ActionChip(
            avatar: Icon(
              pro ? Icons.folder_outlined : Icons.lock_outline,
              size: 18,
              color: Colors.white,
            ),
            label: Text(label),
            labelStyle: const TextStyle(color: Colors.white),
            backgroundColor: const Color(0x99000000),
            onPressed: pro ? _openProjects : _openProScreen,
          ),
        );
      },
    );
  }

  Future<void> _openProjects() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: AnimatedBuilder(
            animation: widget.settings,
            builder: (ctx, _) {
              final current = widget.settings.project;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ListTile(
                    title: Text('Project (gallery album)'),
                    subtitle: Text(
                      'Photos are saved to an album named after the project.',
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      current.isEmpty
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    title: const Text('Default (SiteStamp)'),
                    onTap: () {
                      widget.settings.selectProject('');
                      Navigator.of(ctx).pop();
                    },
                  ),
                  for (final p in widget.settings.projects)
                    ListTile(
                      leading: Icon(
                        p == current
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                      ),
                      title: Text(p),
                      subtitle: Text(StampData.albumFor(p)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Remove from list (photos stay in gallery)',
                        onPressed: () => widget.settings.removeProject(p),
                      ),
                      onTap: () {
                        widget.settings.selectProject(p);
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('New project'),
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      await _newProjectDialog();
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _newProjectDialog() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New project'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          decoration: const InputDecoration(hintText: 'e.g. Tower A, Site 12'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null && name.trim().isNotEmpty) {
      await widget.settings.addProject(name);
    }
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

  void _openProScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProScreen(
          billing: widget.billing,
          entitlements: widget.entitlements,
        ),
      ),
    );
  }

  Future<void> _openPrivacyPolicy() async {
    try {
      final ok = await launchUrl(
        Uri.parse(kPrivacyPolicyUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!ok) _toast('Could not open the privacy policy.');
    } catch (_) {
      _toast('Could not open the privacy policy.');
    }
  }

  Future<void> _emailSupport() async {
    try {
      final ok = await launchUrl(
        Uri(
          scheme: 'mailto',
          path: kSupportEmail,
          queryParameters: {'subject': 'SiteStamp support'},
        ),
      );
      if (!ok) _toast('No email app found. Write to $kSupportEmail');
    } catch (_) {
      _toast('No email app found. Write to $kSupportEmail');
    }
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (!pro) ...[
                              const Icon(Icons.lock_outline, size: 16),
                              const SizedBox(width: 6),
                            ],
                            Text(pro
                                ? 'Stamp position and size'
                                : 'Stamp position and size (Pro)'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<StampPosition>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(
                              value: StampPosition.bottom,
                              label: Text('Bottom'),
                            ),
                            ButtonSegment(
                              value: StampPosition.top,
                              label: Text('Top'),
                            ),
                          ],
                          selected: {widget.settings.stampStyle.position},
                          onSelectionChanged: pro
                              ? (s) => widget.settings.setStampPosition(s.first)
                              : null,
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<StampSize>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(
                              value: StampSize.small,
                              label: Text('Small'),
                            ),
                            ButtonSegment(
                              value: StampSize.medium,
                              label: Text('Medium'),
                            ),
                            ButtonSegment(
                              value: StampSize.large,
                              label: Text('Large'),
                            ),
                          ],
                          selected: {widget.settings.stampStyle.size},
                          onSelectionChanged: pro
                              ? (s) => widget.settings.setStampSize(s.first)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Grid lines'),
                    subtitle: const Text('Rule-of-thirds guide while framing.'),
                    value: widget.settings.showGrid,
                    onChanged: (v) => widget.settings.setShowGrid(v),
                  ),
                  ListTile(
                    leading: Icon(pro ? Icons.verified : Icons.workspace_premium),
                    title: Text(pro ? 'SiteStamp Pro' : 'Upgrade to SiteStamp Pro'),
                    subtitle: Text(
                      pro
                          ? 'No branding, address on photos, 10 saved notes.'
                          : 'Remove the "Made with SiteStamp" line, add the '
                              'street address, and keep 10 saved notes.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _openProScreen();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Privacy policy'),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: _openPrivacyPolicy,
                  ),
                  ListTile(
                    leading: const Icon(Icons.mail_outline),
                    title: const Text('Contact support'),
                    subtitle: const Text(kSupportEmail),
                    onTap: _emailSupport,
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

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x66FFFFFF)
      ..strokeWidth = 1;
    for (var i = 1; i <= 2; i++) {
      final x = size.width * i / 3;
      final y = size.height * i / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
