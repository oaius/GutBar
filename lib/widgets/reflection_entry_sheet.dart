import 'package:flutter/material.dart';

import '../services/reflection_service.dart';

class ReflectionEntrySheet extends StatefulWidget {
  final VoidCallback? onSaved;
  final DateTime? now;

  const ReflectionEntrySheet({super.key, this.onSaved, this.now});

  @override
  State<ReflectionEntrySheet> createState() => _ReflectionEntrySheetState();
}

class _ReflectionEntrySheetState extends State<ReflectionEntrySheet> {
  static const _inputTextStyle = TextStyle(
    color: Colors.white,
    fontFamily: 'monospace',
  );
  static const _hintTextStyle = TextStyle(
    color: Color(0xFF888888),
    fontFamily: 'monospace',
  );
  static const _yearAgoTextStyle = TextStyle(
    color: Color(0xFF888888),
    fontFamily: 'monospace',
    fontSize: 13,
  );
  static const _cursorColor = Color(0xFF00CC44);
  static const _underlineColor = Color(0xFF888888);

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
                style: _yearAgoTextStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: _controller,
              autofocus: true,
              cursorColor: _cursorColor,
              style: _inputTextStyle,
              decoration: const InputDecoration(
                hintText: 'One thing you did today',
                hintStyle: _hintTextStyle,
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: _underlineColor),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: _cursorColor),
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
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF888888)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00CC44),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: _save,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
