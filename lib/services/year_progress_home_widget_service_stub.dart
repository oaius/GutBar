import 'dart:async';

import 'package:flutter/foundation.dart';

import '../utils/year_progress.dart';

class YearProgressHomeWidgetService {
  static Future<void> initialize() async {}

  static Future<void> updateWidgetData([DateTime? now]) async {}

  static StreamSubscription<dynamic>? listenForWidgetLaunches(
    VoidCallback onLaunch,
  ) {
    return null;
  }
}

@visibleForTesting
class YearProgressWidgetSnapshot {
  final String title;
  final String shortTitle;
  final String daysLeftText;
  final String dateText;
  final int progressBasisPoints;
  final String updatedAtIsoString;

  const YearProgressWidgetSnapshot({
    required this.title,
    required this.shortTitle,
    required this.daysLeftText,
    required this.dateText,
    required this.progressBasisPoints,
    required this.updatedAtIsoString,
  });

  factory YearProgressWidgetSnapshot.from(DateTime now) {
    final progress = yearProgress(now).clamp(0.0, 1.0).toDouble();
    final percent = (progress * 100).toStringAsFixed(0);
    final remaining = daysLeftInYear(now);
    final month = _monthNames[now.month - 1];

    return YearProgressWidgetSnapshot(
      title: '$percent% of ${now.year} has passed',
      shortTitle: '${now.year}: $percent%',
      daysLeftText: '$remaining days left',
      dateText: '$month ${now.day}',
      progressBasisPoints: (progress * 10000).round().clamp(0, 10000),
      updatedAtIsoString: now.toIso8601String(),
    );
  }
}

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
