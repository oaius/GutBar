import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/reflection.dart';

class ReflectionYearGrid extends StatefulWidget {
  final List<Reflection> reflections;
  final DateTime? now;

  const ReflectionYearGrid({super.key, required this.reflections, this.now});

  @override
  State<ReflectionYearGrid> createState() => _ReflectionYearGridState();
}

class _ReflectionYearGridState extends State<ReflectionYearGrid> {
  static const double _fallbackWidth = 360;
  static const double _minCellPitch = 10;
  static const double _maxCellPitch = 13;

  static const Color _filledColor = Color(0xFF00CC44);
  static const Color _emptyBorderColor = Color(0xFF2A2A2A);
  static const Color _placeholderBorderColor = Color(0xFF141414);
  static const Color _todayBorderColor = Color(0xFFCCCCCC);
  static const Color _labelColor = Color(0xFF666666);
  static const Color _textColor = Color(0xFFCCCCCC);

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollToLatestWeek();
  }

  @override
  void didUpdateWidget(covariant ReflectionYearGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.now != widget.now ||
        oldWidget.reflections != widget.reflections) {
      _scrollToLatestWeek();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToLatestWeek() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll > 0) {
        _scrollController.jumpTo(maxScroll);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(widget.now ?? DateTime.now());
    final startOfYear = DateTime(today.year, 1, 1);
    final gridStart = startOfYear.subtract(
      Duration(days: _weekdayIndex(startOfYear)),
    );
    final gridEnd = today.add(Duration(days: 6 - _weekdayIndex(today)));
    final weekCount = gridEnd.difference(gridStart).inDays ~/ 7 + 1;

    final reflectionsByDate = <DateTime, Reflection>{
      for (final reflection in widget.reflections)
        if (reflection.date.year == today.year)
          _dateOnly(reflection.date): reflection,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _GridMetrics.forWidth(constraints.maxWidth, weekCount);
        final gridWidth = weekCount * metrics.cellPitch;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (metrics.showDayLabels) _buildDayLabels(metrics),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: gridWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMonthLabels(gridStart, today, weekCount, metrics),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(
                          weekCount,
                          (weekIndex) => _buildWeekColumn(
                            context: context,
                            gridStart: gridStart,
                            weekIndex: weekIndex,
                            startOfYear: startOfYear,
                            today: today,
                            reflectionsByDate: reflectionsByDate,
                            metrics: metrics,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDayLabels(_GridMetrics metrics) {
    const labels = ['', 'Mon', '', 'Wed', '', 'Fri', ''];

    return SizedBox(
      width: metrics.dayLabelWidth,
      child: Column(
        children: [
          SizedBox(height: metrics.monthLabelHeight),
          for (final label in labels)
            SizedBox(
              height: metrics.cellPitch,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  style: TextStyle(
                    color: _labelColor,
                    fontFamily: 'monospace',
                    fontSize: metrics.labelFontSize,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMonthLabels(
    DateTime gridStart,
    DateTime today,
    int weekCount,
    _GridMetrics metrics,
  ) {
    final labels = <_MonthLabel>[];
    for (var month = 1; month <= today.month; month++) {
      final firstOfMonth = DateTime(today.year, month, 1);
      labels.add(
        _MonthLabel(
          column: firstOfMonth.difference(gridStart).inDays ~/ 7,
          label: DateFormat.MMM().format(firstOfMonth),
        ),
      );
    }

    return SizedBox(
      height: metrics.monthLabelHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final monthLabel in labels)
            Positioned(
              left:
                  monthLabel.column.clamp(0, weekCount - 1) * metrics.cellPitch,
              top: 0,
              child: Text(
                monthLabel.label,
                style: TextStyle(
                  color: _labelColor,
                  fontFamily: 'monospace',
                  fontSize: metrics.labelFontSize,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeekColumn({
    required BuildContext context,
    required DateTime gridStart,
    required int weekIndex,
    required DateTime startOfYear,
    required DateTime today,
    required Map<DateTime, Reflection> reflectionsByDate,
    required _GridMetrics metrics,
  }) {
    return SizedBox(
      width: metrics.cellPitch,
      child: Column(
        children: List.generate(7, (dayIndex) {
          final date = gridStart.add(Duration(days: weekIndex * 7 + dayIndex));
          return _buildDayCell(
            context: context,
            date: date,
            startOfYear: startOfYear,
            today: today,
            reflection: reflectionsByDate[_dateOnly(date)],
            metrics: metrics,
          );
        }),
      ),
    );
  }

  Widget _buildDayCell({
    required BuildContext context,
    required DateTime date,
    required DateTime startOfYear,
    required DateTime today,
    required Reflection? reflection,
    required _GridMetrics metrics,
  }) {
    final isInYear = !date.isBefore(startOfYear) && date.year == today.year;
    final isFuture = date.isAfter(today);
    final isPlaceholder = !isInYear || isFuture;
    final isToday = _isSameDay(date, today);
    final hasReflection = !isPlaceholder && reflection != null;

    final borderColor = isToday
        ? _todayBorderColor
        : isPlaceholder
        ? _placeholderBorderColor
        : hasReflection
        ? _filledColor
        : _emptyBorderColor;

    return SizedBox(
      width: metrics.cellPitch,
      height: metrics.cellPitch,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: hasReflection
            ? () => _showReflection(context, reflection)
            : null,
        child: Center(
          child: Container(
            width: metrics.cellSize,
            height: metrics.cellSize,
            decoration: BoxDecoration(
              color: hasReflection ? _filledColor : Colors.transparent,
              borderRadius: BorderRadius.circular(metrics.cellRadius),
              border: Border.all(color: borderColor, width: isToday ? 1.2 : 1),
            ),
          ),
        ),
      ),
    );
  }

  void _showReflection(BuildContext context, Reflection reflection) {
    final dateLabel = DateFormat.yMMMMd().format(reflection.date);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateLabel,
                        style: const TextStyle(
                          color: _labelColor,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SelectableText(
                        reflection.text,
                        style: const TextStyle(
                          color: _textColor,
                          fontFamily: 'monospace',
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static int _weekdayIndex(DateTime date) => date.weekday % 7;

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _MonthLabel {
  final int column;
  final String label;

  const _MonthLabel({required this.column, required this.label});
}

class _GridMetrics {
  final double cellSize;
  final double cellPitch;
  final double cellRadius;
  final double monthLabelHeight;
  final double dayLabelWidth;
  final double labelFontSize;
  final bool showDayLabels;

  const _GridMetrics({
    required this.cellSize,
    required this.cellPitch,
    required this.cellRadius,
    required this.monthLabelHeight,
    required this.dayLabelWidth,
    required this.labelFontSize,
    required this.showDayLabels,
  });

  factory _GridMetrics.forWidth(double maxWidth, int weekCount) {
    final availableWidth = maxWidth.isFinite && maxWidth > 0
        ? maxWidth
        : _ReflectionYearGridState._fallbackWidth;
    final showDayLabels = availableWidth >= 300;
    final dayLabelWidth = showDayLabels
        ? availableWidth < 360
              ? 22.0
              : 26.0
        : 0.0;
    final graphWidth = availableWidth - dayLabelWidth;
    final fittedPitch = (graphWidth / weekCount)
        .clamp(
          _ReflectionYearGridState._minCellPitch,
          _ReflectionYearGridState._maxCellPitch,
        )
        .toDouble();
    final cellSize = (fittedPitch - 3.5).clamp(7.0, 9.0).toDouble();

    return _GridMetrics(
      cellSize: cellSize,
      cellPitch: fittedPitch,
      cellRadius: (cellSize / 4).clamp(1.5, 2.25).toDouble(),
      monthLabelHeight: fittedPitch <= 10.5 ? 14 : 16,
      dayLabelWidth: dayLabelWidth,
      labelFontSize: fittedPitch <= 10.5 ? 8 : 9,
      showDayLabels: showDayLabels,
    );
  }
}
