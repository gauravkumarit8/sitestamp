import 'package:flutter/material.dart';

import '../models/stamp_style.dart';

/// Small mock photo showing where and how large the stamp will be.
class StampPreview extends StatelessWidget {
  const StampPreview({super.key, required this.lines, required this.style});

  final List<String> lines;
  final StampStyle style;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final fontSize = w * style.size.fontFactor;
            final pad = w * 0.03;
            final atTop = style.position == StampPosition.top;
            return Stack(
              children: [
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF455A64), Color(0xFF90A4AE)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: atTop ? 0 : null,
                  bottom: atTop ? null : 0,
                  child: Container(
                    color: const Color(0x99000000),
                    padding: EdgeInsets.all(pad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < lines.length; i++)
                          Text(
                            lines[i],
                            style: TextStyle(
                              color: lines[i].startsWith('Made with')
                                  ? const Color(0xB3FFFFFF)
                                  : Colors.white,
                              fontSize: fontSize,
                              height: 1.25,
                              fontWeight:
                                  i == 0 ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
