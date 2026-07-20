import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:workmanager/workmanager.dart';

import '../utils/year_progress.dart';

const _yearProgressWidgetTask = 'yearProgressWidgetDailyUpdate';

@pragma('vm:entry-point')
void yearProgressWidgetCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != _yearProgressWidgetTask) return true;

    try {
      await YearProgressHomeWidgetService.updateWidgetData();
      return true;
    } catch (_) {
      return false;
    }
  });
}

class YearProgressHomeWidgetService {
  static const androidProviderName = 'YearProgressWidgetProvider';
  static const androidProviderQualifiedName =
      'com.example.progressbar.YearProgressWidgetProvider';
  static const iOSWidgetName = 'YearProgressWidget';

  static const titleKey = 'year_progress_title';
  static const shortTitleKey = 'year_progress_short_title';
  static const daysLeftKey = 'year_progress_days_left';
  static const dateKey = 'year_progress_date';
  static const progressKey = 'year_progress_basis_points';
  static const updatedAtKey = 'year_progress_updated_at';

  static Future<void> initialize() async {
    if (!Platform.isAndroid) return;

    await Workmanager().initialize(yearProgressWidgetCallbackDispatcher);
    await updateWidgetData();
    await Workmanager().registerPeriodicTask(
      _yearProgressWidgetTask,
      _yearProgressWidgetTask,
      frequency: const Duration(hours: 24),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
  }

  static Future<void> updateWidgetData([DateTime? now]) async {
    if (!Platform.isAndroid) return;

    final snapshot = YearProgressWidgetSnapshot.from(now ?? DateTime.now());
    await Future.wait<bool?>([
      HomeWidget.saveWidgetData<String>(titleKey, snapshot.title),
      HomeWidget.saveWidgetData<String>(shortTitleKey, snapshot.shortTitle),
      HomeWidget.saveWidgetData<String>(daysLeftKey, snapshot.daysLeftText),
      HomeWidget.saveWidgetData<String>(dateKey, snapshot.dateText),
      HomeWidget.saveWidgetData<int>(progressKey, snapshot.progressBasisPoints),
      HomeWidget.saveWidgetData<String>(
        updatedAtKey,
        snapshot.updatedAtIsoString,
      ),
    ]);

    await HomeWidget.updateWidget(
      name: androidProviderName,
      iOSName: iOSWidgetName,
      qualifiedAndroidName: androidProviderQualifiedName,
    );
  }

  static StreamSubscription<Uri?>? listenForWidgetLaunches(
    VoidCallback onLaunch,
  ) {
    if (!Platform.isAndroid) return null;

    return HomeWidget.widgetClicked.listen((uri) {
      if (uri == null || uri.scheme != 'progressbar') return;
      if (uri.host == 'year') onLaunch();
    });
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
