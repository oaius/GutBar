import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../services/reflection_service.dart';
import '../models/reflection.dart';
import '../theme/app_theme.dart';
import '../widgets/reflection_year_grid.dart';

enum _ReflectionMenuAction { exportEntries, importEntries }

class ReflectionLogScreen extends StatefulWidget {
  final DateTime? now;

  const ReflectionLogScreen({super.key, this.now});

  @override
  State<ReflectionLogScreen> createState() => _ReflectionLogScreenState();
}

class _ReflectionLogScreenState extends State<ReflectionLogScreen> {
  List<Reflection> _items = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _items = ReflectionService.getAll();
    });
  }

  Future<void> _exportEntries() async {
    final entries = ReflectionService.getAll();
    if (entries.isEmpty) {
      _showMessage('No entries to export');
      return;
    }

    final backupJson = ReflectionService.exportBackupJson();
    final backupDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final filename = 'reflections_backup_$backupDate.json';
    final renderObject = context.findRenderObject();
    final shareOrigin = renderObject is RenderBox
        ? renderObject.localToGlobal(Offset.zero) & renderObject.size
        : null;

    try {
      await SharePlus.instance.share(
        ShareParams(
          title: 'Export entries',
          subject: 'Reflections backup',
          files: [
            XFile.fromData(
              Uint8List.fromList(utf8.encode(backupJson)),
              mimeType: 'application/json',
              name: filename,
            ),
          ],
          fileNameOverrides: [filename],
          sharePositionOrigin: shareOrigin,
        ),
      );
    } catch (_) {
      _showMessage('Could not export entries');
    }
  }

  Future<void> _importEntries() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
      if (!mounted || result == null || result.files.isEmpty) return;

      final bytes = result.files.single.bytes;
      if (bytes == null) {
        _showMessage('Could not read selected file');
        return;
      }

      final imported = ReflectionService.parseBackupJson(utf8.decode(bytes));
      if (imported.isEmpty) {
        _showMessage('No entries found in backup');
        return;
      }

      final importResult = await ReflectionService.importEntries(
        imported,
        resolveConflict: _resolveImportConflict,
      );
      if (!mounted) return;

      _reload();
      _showMessage(_importResultMessage(importResult));
    } on FormatException {
      _showMessage('Invalid reflections backup file');
    } catch (_) {
      _showMessage('Could not import entries');
    }
  }

  Future<ReflectionImportChoice> _resolveImportConflict(
    ReflectionImportConflict conflict,
  ) async {
    if (!mounted) return ReflectionImportChoice.keepExisting;

    final dateLabel = DateFormat.yMMMd().format(conflict.imported.date);
    final choice = await showDialog<ReflectionImportChoice>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final colors = context.progressColors;

        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text(
            'Entry already exists',
            style: TextStyle(
              color: colors.textPrimary,
              fontFamily: 'monospace',
              letterSpacing: 0,
            ),
          ),
          content: Text(
            '$dateLabel already has an entry. Keep both saves the imported copy on the next open date.',
            style: TextStyle(
              color: colors.textSecondary,
              fontFamily: 'monospace',
              letterSpacing: 0,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(
                context,
              ).pop(ReflectionImportChoice.keepExisting),
              child: Text(
                'Keep existing',
                style: TextStyle(color: colors.textTertiary),
              ),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(ReflectionImportChoice.overwrite),
              child: Text(
                'Overwrite',
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(ReflectionImportChoice.keepBoth),
              child: Text('Keep both', style: TextStyle(color: colors.accent)),
            ),
          ],
        );
      },
    );

    return choice ?? ReflectionImportChoice.keepExisting;
  }

  String _importResultMessage(ReflectionImportResult result) {
    if (result.changed == 0) return 'No entries imported';

    final label = result.changed == 1 ? 'entry' : 'entries';
    return 'Imported ${result.changed} $label';
  }

  void _showMessage(String message) {
    if (!mounted) return;
    final colors = context.progressColors;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: colors.surfaceAlt,
        content: Text(
          message,
          style: TextStyle(
            color: colors.textSecondary,
            fontFamily: 'monospace',
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.progressColors;
    final df = DateFormat.yMMMd();
    final summary = _RetrospectiveSummary.from(
      reflections: _items,
      now: widget.now ?? DateTime.now(),
    );

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Reflections'),
        actions: [
          PopupMenuButton<_ReflectionMenuAction>(
            color: colors.surfaceAlt,
            icon: Icon(Icons.more_vert, color: colors.icon),
            tooltip: 'Reflection options',
            onSelected: (action) {
              switch (action) {
                case _ReflectionMenuAction.exportEntries:
                  _exportEntries();
                  break;
                case _ReflectionMenuAction.importEntries:
                  _importEntries();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _ReflectionMenuAction.exportEntries,
                enabled: _items.isNotEmpty,
                child: Text(
                  'Export entries',
                  style: _menuTextStyle(context, _items.isNotEmpty),
                ),
              ),
              PopupMenuItem(
                value: _ReflectionMenuAction.importEntries,
                child: Text(
                  'Import entries',
                  style: _menuTextStyle(context, true),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Year overview',
              style: TextStyle(
                color: colors.textTertiary,
                fontFamily: 'monospace',
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
            ReflectionYearGrid(reflections: _items),
            const SizedBox(height: 16),
            _RetrospectiveSummaryView(summary: summary),
            const SizedBox(height: 16),
            if (_items.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'No entries yet - tap a day to start',
                style: TextStyle(
                  color: colors.textTertiary,
                  fontFamily: 'monospace',
                  letterSpacing: 0,
                ),
              ),
            ] else ...[
              Text(
                'Entries',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontFamily: 'monospace',
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final r = _items[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        df.format(r.date),
                        style: TextStyle(
                          color: colors.textTertiary,
                          fontFamily: 'monospace',
                          letterSpacing: 0,
                        ),
                      ),
                      subtitle: Text(
                        r.text,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontFamily: 'monospace',
                          letterSpacing: 0,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  TextStyle _menuTextStyle(BuildContext context, bool enabled) {
    final colors = context.progressColors;

    return TextStyle(
      color: enabled ? colors.textSecondary : colors.disabled,
      fontFamily: 'monospace',
      letterSpacing: 0,
    );
  }
}

class _RetrospectiveSummaryView extends StatelessWidget {
  final _RetrospectiveSummary summary;

  const _RetrospectiveSummaryView({required this.summary});

  @override
  Widget build(BuildContext context) {
    final colors = context.progressColors;
    final summaryTextStyle = TextStyle(
      color: colors.textTertiary,
      fontFamily: 'monospace',
      fontSize: 13,
      letterSpacing: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This week: ${summary.weekCount}/${summary.weekElapsedDays} days accounted for',
          style: summaryTextStyle,
        ),
        const SizedBox(height: 4),
        Text(
          'This month: ${summary.monthCount}/${summary.monthElapsedDays} days accounted for',
          style: summaryTextStyle,
        ),
      ],
    );
  }
}

class _RetrospectiveSummary {
  final int weekCount;
  final int weekElapsedDays;
  final int monthCount;
  final int monthElapsedDays;

  const _RetrospectiveSummary({
    required this.weekCount,
    required this.weekElapsedDays,
    required this.monthCount,
    required this.monthElapsedDays,
  });

  factory _RetrospectiveSummary.from({
    required List<Reflection> reflections,
    required DateTime now,
  }) {
    final today = _dateOnly(now);
    final startOfWeek = today.subtract(Duration(days: today.weekday % 7));
    final startOfMonth = DateTime(today.year, today.month);
    final entryDates = {
      for (final reflection in reflections) _dateOnly(reflection.date),
    };

    return _RetrospectiveSummary(
      weekCount: _countDatesBetween(entryDates, startOfWeek, today),
      weekElapsedDays: today.difference(startOfWeek).inDays + 1,
      monthCount: _countDatesBetween(entryDates, startOfMonth, today),
      monthElapsedDays: today.day,
    );
  }

  static int _countDatesBetween(
    Set<DateTime> dates,
    DateTime start,
    DateTime end,
  ) {
    return dates.where((date) {
      return !date.isBefore(start) && !date.isAfter(end);
    }).length;
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
