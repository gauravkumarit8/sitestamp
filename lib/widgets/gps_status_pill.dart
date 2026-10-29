import 'dart:async';

import 'package:flutter/material.dart';

import '../services/location_service.dart';

class GpsStatusPill extends StatefulWidget {
  const GpsStatusPill({super.key, required this.location, this.onTap});

  final LocationService location;
  final VoidCallback? onTap;

  @override
  State<GpsStatusPill> createState() => _GpsStatusPillState();
}

class _GpsStatusPillState extends State<GpsStatusPill> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Re-evaluate freshness even when no new fix arrives.
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = widget.location;
    return AnimatedBuilder(
      animation: Listenable.merge([loc.latest, loc.serviceEnabled]),
      builder: (context, _) {
        final enabled = loc.serviceEnabled.value;
        final fix = loc.freshFix();

        late final Color color;
        late final String label;
        if (!enabled) {
          color = const Color(0xFFE53935);
          label = 'Location off - tap to fix';
        } else if (fix == null) {
          color = const Color(0xFFFB8C00);
          label = 'Acquiring GPS...';
        } else if (fix.isMocked) {
          color = const Color(0xFFE53935);
          label = 'Mock location detected';
        } else if (fix.accuracy > 50) {
          color = const Color(0xFFFB8C00);
          label = 'GPS weak (±${fix.accuracy.round()} m)';
        } else {
          color = const Color(0xFF43A047);
          label = 'GPS Ready (±${fix.accuracy.round()} m)';
        }

        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x99000000),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
