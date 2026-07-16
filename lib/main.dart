import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: YearProgressWidget(),
          ),
        ),
      ),
    );
  }
}

class YearProgressWidget extends StatefulWidget {
  const YearProgressWidget({super.key});

  @override
  State<YearProgressWidget> createState() => _YearProgressWidgetState();
}

class _YearProgressWidgetState extends State<YearProgressWidget> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    // Refresh every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  double _getYearProgress() {
    final startOfYear = DateTime(_now.year, 1, 1);
    final endOfYear = DateTime(_now.year + 1, 1, 1);
    final total = endOfYear.difference(startOfYear).inSeconds;
    final elapsed = _now.difference(startOfYear).inSeconds;
    return elapsed / total;
  }

  int _getDaysLeft() {
    final today = DateTime(_now.year, _now.month, _now.day);
    final lastDay = DateTime(_now.year, 12, 31);
    return lastDay.difference(today).inDays + 1; // inclusive: today counts
  }

  String _formatDate() {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final month = months[_now.month - 1];
    final day = _now.day;
    final hour = _now.hour.toString().padLeft(2, '0');
    final minute = _now.minute.toString().padLeft(2, '0');
    return '$month $day, $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _getYearProgress();
    final percent = (progress * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Headline
          Text(
            '$percent% of ${_now.year} has passed',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          // Days left (supporting info)
          Text(
            '${_getDaysLeft()} days left in ${_now.year}',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 6),
          // Subtitle date
          Text(
            _formatDate(),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 20,
              child: Stack(
                children: [
                  // underlying progress indicator
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFF2A2A2A),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00CC44)),
                    minHeight: 20,
                  ),
                  // tick marks overlay
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _TickPainter(
                          positions: const [0.25, 0.5, 0.75],
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
      ),
    );
  }
}

class _TickPainter extends CustomPainter {
  final List<double> positions;
  final Color color;
  final double inset;

  _TickPainter({required this.positions, required this.color, this.inset = 3.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final top = inset;
    final bottom = size.height - inset;

    for (final p in positions) {
      final x = (p.clamp(0.0, 1.0)) * size.width;
      canvas.drawLine(Offset(x, top), Offset(x, bottom), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TickPainter oldDelegate) {
    return oldDelegate.positions != positions || oldDelegate.color != color || oldDelegate.inset != inset;
  }
}