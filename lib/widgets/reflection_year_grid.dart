import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/reflection.dart';
import '../theme/app_theme.dart';

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
  static const double _minTapTargetSize = 44;
  static const double _monthLabelTapWidth = 44;
  static const Duration _monthTapFeedbackDuration = Duration(milliseconds: 120);
  static const Duration _monthScrollDuration = Duration(milliseconds: 260);

  final ScrollController _scrollController = ScrollController();
  double _latestHorizontalHitInset = 0;
  int? _pressedMonthColumn;

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
        final target = (maxScroll - _latestHorizontalHitInset)
            .clamp(0.0, maxScroll)
            .toDouble();
        _scrollController.jumpTo(target);
      }
    });
  }

  void _scrollToMonth(int column, _GridMetrics metrics) {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final target = (metrics.horizontalHitInset + column * metrics.cellPitch)
        .clamp(0.0, maxScroll)
        .toDouble();
    _scrollController.animateTo(
      target,
      duration: _monthScrollDuration,
      curve: Curves.easeOutCubic,
    );
  }

  void _flashMonthLabel(int column) {
    setState(() => _pressedMonthColumn = column);
    Future<void>.delayed(_monthTapFeedbackDuration, () {
      if (mounted && _pressedMonthColumn == column) {
        setState(() => _pressedMonthColumn = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.progressColors;
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
        final contentWidth = gridWidth + metrics.horizontalHitInset * 2;
        _latestHorizontalHitInset = metrics.horizontalHitInset;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (metrics.showDayLabels) _buildDayLabels(metrics, colors),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: contentWidth,
                  height: metrics.timelineHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: metrics.horizontalHitInset,
                        top: metrics.topHitInset + metrics.monthLabelHeight,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(
                            weekCount,
                            (weekIndex) => _buildWeekColumn(
                              gridStart: gridStart,
                              weekIndex: weekIndex,
                              startOfYear: startOfYear,
                              today: today,
                              reflectionsByDate: reflectionsByDate,
                              metrics: metrics,
                              colors: colors,
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTapUp: (details) => _handleGridTap(
                            context: context,
                            localPosition: details.localPosition,
                            gridStart: gridStart,
                            weekCount: weekCount,
                            startOfYear: startOfYear,
                            today: today,
                            reflectionsByDate: reflectionsByDate,
                            metrics: metrics,
                          ),
                        ),
                      ),
                      Positioned(
                        left: metrics.horizontalHitInset,
                        top: metrics.topHitInset,
                        child: _buildMonthLabels(
                          gridStart,
                          today,
                          weekCount,
                          metrics,
                          gridWidth,
                          colors,
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

  Widget _buildDayLabels(_GridMetrics metrics, ProgressThemeColors colors) {
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
                    color: colors.textTertiary,
                    fontFamily: 'monospace',
                    fontSize: metrics.labelFontSize,
                    letterSpacing: 0,
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
    double gridWidth,
    ProgressThemeColors colors,
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
      width: gridWidth,
      height: metrics.monthLabelHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final monthLabel in labels)
            Positioned(
              left:
                  monthLabel.column.clamp(0, weekCount - 1) * metrics.cellPitch,
              top: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) =>
                    setState(() => _pressedMonthColumn = monthLabel.column),
                onTapCancel: () => setState(() => _pressedMonthColumn = null),
                onTap: () {
                  _flashMonthLabel(monthLabel.column);
                  _scrollToMonth(monthLabel.column, metrics);
                },
                child: AnimatedOpacity(
                  opacity: _pressedMonthColumn == monthLabel.column ? 0.55 : 1,
                  duration: const Duration(milliseconds: 80),
                  child: SizedBox(
                    width: _monthLabelTapWidth,
                    height: metrics.monthLabelHeight,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        monthLabel.label,
                        style: TextStyle(
                          color: colors.textTertiary,
                          fontFamily: 'monospace',
                          fontSize: metrics.labelFontSize,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeekColumn({
    required DateTime gridStart,
    required int weekIndex,
    required DateTime startOfYear,
    required DateTime today,
    required Map<DateTime, Reflection> reflectionsByDate,
    required _GridMetrics metrics,
    required ProgressThemeColors colors,
  }) {
    return SizedBox(
      width: metrics.cellPitch,
      child: Column(
        children: List.generate(7, (dayIndex) {
          final date = gridStart.add(Duration(days: weekIndex * 7 + dayIndex));
          return _buildDayCell(
            date: date,
            startOfYear: startOfYear,
            today: today,
            reflection: reflectionsByDate[_dateOnly(date)],
            metrics: metrics,
            colors: colors,
          );
        }),
      ),
    );
  }

  Widget _buildDayCell({
    required DateTime date,
    required DateTime startOfYear,
    required DateTime today,
    required Reflection? reflection,
    required _GridMetrics metrics,
    required ProgressThemeColors colors,
  }) {
    final isPlaceholder = _isPlaceholderDate(date, startOfYear, today);
    final isToday = _isSameDay(date, today);
    final hasReflection = !isPlaceholder && reflection != null;

    final borderColor = isToday
        ? colors.textSecondary
        : isPlaceholder
        ? colors.subtleBorder
        : hasReflection
        ? colors.accent
        : colors.border;

    return SizedBox(
      width: metrics.cellPitch,
      height: metrics.cellPitch,
      child: Center(
        child: Container(
          width: metrics.cellSize,
          height: metrics.cellSize,
          decoration: BoxDecoration(
            color: hasReflection ? colors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(metrics.cellRadius),
            border: Border.all(color: borderColor, width: isToday ? 1.2 : 1),
          ),
        ),
      ),
    );
  }

  void _handleGridTap({
    required BuildContext context,
    required Offset localPosition,
    required DateTime gridStart,
    required int weekCount,
    required DateTime startOfYear,
    required DateTime today,
    required Map<DateTime, Reflection> reflectionsByDate,
    required _GridMetrics metrics,
  }) {
    final xInGrid = localPosition.dx - metrics.horizontalHitInset;
    final yInGrid =
        localPosition.dy - metrics.topHitInset - metrics.monthLabelHeight;
    final weekIndex = ((xInGrid - metrics.cellPitch / 2) / metrics.cellPitch)
        .round();
    final dayIndex = ((yInGrid - metrics.cellPitch / 2) / metrics.cellPitch)
        .round();

    if (weekIndex < 0 ||
        weekIndex >= weekCount ||
        dayIndex < 0 ||
        dayIndex >= 7) {
      return;
    }

    final dotCenter = Offset(
      metrics.horizontalHitInset +
          weekIndex * metrics.cellPitch +
          metrics.cellPitch / 2,
      metrics.topHitInset +
          metrics.monthLabelHeight +
          dayIndex * metrics.cellPitch +
          metrics.cellPitch / 2,
    );
    final halfTapTarget = _minTapTargetSize / 2;
    if ((localPosition.dx - dotCenter.dx).abs() > halfTapTarget ||
        (localPosition.dy - dotCenter.dy).abs() > halfTapTarget) {
      return;
    }

    final date = gridStart.add(Duration(days: weekIndex * 7 + dayIndex));
    if (_isPlaceholderDate(date, startOfYear, today)) return;

    final reflection = reflectionsByDate[_dateOnly(date)];
    if (reflection != null) {
      _showReflection(context, reflection);
    }
  }

  void _showReflection(BuildContext context, Reflection reflection) {
    final colors = context.progressColors;
    final dateLabel = DateFormat.yMMMMd().format(reflection.date);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
                        style: TextStyle(
                          color: colors.textTertiary,
                          fontFamily: 'monospace',
                          fontSize: 12,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SelectableText(
                        reflection.text,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontFamily: 'monospace',
                          fontSize: 14,
                          height: 1.35,
                          letterSpacing: 0,
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

  static bool _isPlaceholderDate(
    DateTime date,
    DateTime startOfYear,
    DateTime today,
  ) {
    final isInYear = !date.isBefore(startOfYear) && date.year == today.year;
    final isFuture = date.isAfter(today);
    return !isInYear || isFuture;
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
  final double horizontalHitInset;
  final double topHitInset;
  final double bottomHitInset;
  final double timelineHeight;
  final bool showDayLabels;

  const _GridMetrics({
    required this.cellSize,
    required this.cellPitch,
    required this.cellRadius,
    required this.monthLabelHeight,
    required this.dayLabelWidth,
    required this.labelFontSize,
    required this.horizontalHitInset,
    required this.topHitInset,
    required this.bottomHitInset,
    required this.timelineHeight,
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
    final monthLabelHeight = fittedPitch <= 10.5 ? 14.0 : 16.0;
    final halfTapTarget = _ReflectionYearGridState._minTapTargetSize / 2;
    final halfPitch = fittedPitch / 2;
    final horizontalHitInset = halfTapTarget - halfPitch;
    final topHitInset = (halfTapTarget - monthLabelHeight - halfPitch)
        .clamp(0.0, double.infinity)
        .toDouble();
    final bottomHitInset = (halfTapTarget - halfPitch)
        .clamp(0.0, double.infinity)
        .toDouble();
    final gridHeight = fittedPitch * 7;

    return _GridMetrics(
      cellSize: cellSize,
      cellPitch: fittedPitch,
      cellRadius: (cellSize / 4).clamp(1.5, 2.25).toDouble(),
      monthLabelHeight: monthLabelHeight,
      dayLabelWidth: dayLabelWidth,
      labelFontSize: fittedPitch <= 10.5 ? 8 : 9,
      horizontalHitInset: horizontalHitInset,
      topHitInset: topHitInset,
      bottomHitInset: bottomHitInset,
      timelineHeight:
          topHitInset + monthLabelHeight + gridHeight + bottomHitInset,
      showDayLabels: showDayLabels,
    );
  }
}
