import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ProgressBarWidget extends StatelessWidget {
  final double percentage;
  final String primaryText;
  final String secondaryText;
  final String? detailText;
  final List<double> tickPositions;

  const ProgressBarWidget({
    super.key,
    required this.percentage,
    required this.primaryText,
    required this.secondaryText,
    required this.tickPositions,
    this.detailText,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.progressColors;
    final clampedPercentage = percentage.clamp(0.0, 1.0).toDouble();
    final headlineStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: colors.textPrimary,
      letterSpacing: 0,
    );
    final supportingStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 13,
      color: colors.textTertiary,
      letterSpacing: 0,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(primaryText, style: headlineStyle),
        const SizedBox(height: 4),
        Text(secondaryText, style: supportingStyle),
        if (detailText != null) ...[
          const SizedBox(height: 6),
          Text(detailText!, style: supportingStyle),
        ],
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 20,
            child: Stack(
              children: [
                LinearProgressIndicator(
                  value: clampedPercentage,
                  backgroundColor: colors.progressTrack,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
                  minHeight: 20,
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _TickPainter(
                        positions: tickPositions,
                        color: colors.progressTick,
                        inset: 3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TickPainter extends CustomPainter {
  final List<double> positions;
  final Color color;
  final double inset;

  _TickPainter({
    required this.positions,
    required this.color,
    this.inset = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final top = inset;
    final bottom = size.height - inset;

    for (final p in positions) {
      final x = p.clamp(0.0, 1.0) * size.width;
      canvas.drawLine(Offset(x, top), Offset(x, bottom), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TickPainter oldDelegate) {
    return !listEquals(oldDelegate.positions, positions) ||
        oldDelegate.color != color ||
        oldDelegate.inset != inset;
  }
}
