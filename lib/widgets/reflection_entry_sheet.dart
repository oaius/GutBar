import 'package:flutter/material.dart';

import '../services/reflection_service.dart';
import '../theme/app_theme.dart';

class ReflectionEntrySheet extends StatefulWidget {
  final VoidCallback? onSaved;
  final DateTime? now;

  const ReflectionEntrySheet({super.key, this.onSaved, this.now});

  @override
  State<ReflectionEntrySheet> createState() => _ReflectionEntrySheetState();
}

class _ReflectionEntrySheetState extends State<ReflectionEntrySheet> {
  final _controller = TextEditingController();
  late DateTime _today;
  String? _yearAgoText;

  @override
  void initState() {
    super.initState();
    _today = _dateOnly(widget.now ?? DateTime.now());
    _loadReflectionContext();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _loadReflectionContext() {
    final today = ReflectionService.getForDate(_today);
    if (today != null) _controller.text = today.text;

    final lastYearDate = _sameCalendarDateLastYear(_today);
    if (lastYearDate == null) return;

    _yearAgoText = ReflectionService.getForDate(lastYearDate)?.text;
  }

  void _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      Navigator.of(context).pop(false);
      return;
    }
    await ReflectionService.saveForDate(_today, text);
    if (!mounted) return;
    widget.onSaved?.call();
    Navigator.of(context).pop(true);
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime? _sameCalendarDateLastYear(DateTime date) {
    final candidate = DateTime(date.year - 1, date.month, date.day);
    if (candidate.year != date.year - 1 ||
        candidate.month != date.month ||
        candidate.day != date.day) {
      return null;
    }
    return candidate;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.progressColors;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_yearAgoText != null) ...[
              Text(
                'A year ago: $_yearAgoText',
                style: TextStyle(
                  color: colors.textTertiary,
                  fontFamily: 'monospace',
                  fontSize: 13,
                  letterSpacing: 0,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: _controller,
              autofocus: true,
              cursorColor: colors.accent,
              style: TextStyle(
                color: colors.textPrimary,
                fontFamily: 'monospace',
                letterSpacing: 0,
              ),
              decoration: InputDecoration(
                hintText: 'One thing you did today',
                hintStyle: TextStyle(
                  color: colors.textTertiary,
                  fontFamily: 'monospace',
                  letterSpacing: 0,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: colors.textTertiary),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: colors.accent),
                ),
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _save, child: const Text('Save')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
