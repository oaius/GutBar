import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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

  static const _headlineStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  static const _supportingStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 13,
    color: Color(0xFF888888),
  );

  @override
  Widget build(BuildContext context) {
    final clampedPercentage = percentage.clamp(0.0, 1.0).toDouble();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(primaryText, style: _headlineStyle),
        const SizedBox(height: 4),
        Text(secondaryText, style: _supportingStyle),
        if (detailText != null) ...[
          const SizedBox(height: 6),
          Text(detailText!, style: _supportingStyle),
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
                  backgroundColor: const Color(0xFF2A2A2A),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF00CC44),
                  ),
                  minHeight: 20,
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _TickPainter(
                        positions: tickPositions,
                        color: Colors.white24,
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
