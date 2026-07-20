import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../services/reflection_service.dart';
import '../models/reflection.dart';
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

  static const _summaryTextStyle = TextStyle(
    color: Color(0xFF888888),
    fontFamily: 'monospace',
    fontSize: 13,
  );

  static TextStyle _menuTextStyle(bool enabled) => TextStyle(
    color: enabled ? const Color(0xFFCCCCCC) : const Color(0xFF555555),
    fontFamily: 'monospace',
  );

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
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text(
            'Entry already exists',
            style: TextStyle(color: Colors.white, fontFamily: 'monospace'),
          ),
          content: Text(
            '$dateLabel already has an entry. Keep both saves the imported copy on the next open date.',
            style: const TextStyle(
              color: Color(0xFFCCCCCC),
              fontFamily: 'monospace',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(
                context,
              ).pop(ReflectionImportChoice.keepExisting),
              child: const Text(
                'Keep existing',
                style: TextStyle(color: Color(0xFF888888)),
              ),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(ReflectionImportChoice.overwrite),
              child: const Text(
                'Overwrite',
                style: TextStyle(color: Color(0xFFCCCCCC)),
              ),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(ReflectionImportChoice.keepBoth),
              child: const Text(
                'Keep both',
                style: TextStyle(color: Color(0xFF00CC44)),
              ),
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF111111),
        content: Text(
          message,
          style: const TextStyle(
            color: Color(0xFFCCCCCC),
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMd();
    final summary = _RetrospectiveSummary.from(
      reflections: _items,
      now: widget.now ?? DateTime.now(),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Reflections',
          style: TextStyle(fontFamily: 'monospace'),
        ),
        actions: [
          PopupMenuButton<_ReflectionMenuAction>(
            color: const Color(0xFF111111),
            icon: const Icon(Icons.more_vert, color: Color(0xFF888888)),
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
                  style: _menuTextStyle(_items.isNotEmpty),
                ),
              ),
              PopupMenuItem(
                value: _ReflectionMenuAction.importEntries,
                child: Text('Import entries', style: _menuTextStyle(true)),
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
            const Text(
              'Year overview',
              style: TextStyle(
                color: Color(0xFF888888),
                fontFamily: 'monospace',
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
                'No entries yet — tap a day to start',
                style: const TextStyle(
                  color: Color(0xFF888888),
                  fontFamily: 'monospace',
                ),
              ),
            ] else ...[
              const Text(
                'Entries',
                style: TextStyle(color: Colors.white, fontFamily: 'monospace'),
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
                        style: const TextStyle(
                          color: Color(0xFF888888),
                          fontFamily: 'monospace',
                        ),
                      ),
                      subtitle: Text(
                        r.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'monospace',
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
}

class _RetrospectiveSummaryView extends StatelessWidget {
  final _RetrospectiveSummary summary;

  const _RetrospectiveSummaryView({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This week: ${summary.weekCount}/${summary.weekElapsedDays} days accounted for',
          style: _ReflectionLogScreenState._summaryTextStyle,
        ),
        const SizedBox(height: 4),
        Text(
          'This month: ${summary.monthCount}/${summary.monthElapsedDays} days accounted for',
          style: _ReflectionLogScreenState._summaryTextStyle,
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
