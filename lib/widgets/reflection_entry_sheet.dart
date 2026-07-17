import 'package:flutter/material.dart';

import '../services/reflection_service.dart';

class ReflectionEntrySheet extends StatefulWidget {
  final VoidCallback? onSaved;
  const ReflectionEntrySheet({Key? key, this.onSaved}) : super(key: key);

  @override
  State<ReflectionEntrySheet> createState() => _ReflectionEntrySheetState();
}

class _ReflectionEntrySheetState extends State<ReflectionEntrySheet> {
  final _controller = TextEditingController();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final today = ReflectionService.getToday();
      if (today != null) _controller.text = today.text;
      _initialized = true;
    }
  }

  void _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      Navigator.of(context).pop(false);
      return;
    }
    await ReflectionService.saveToday(text);
    widget.onSaved?.call();
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'One thing you did today',
                border: UnderlineInputBorder(),
              ),
              onSubmitted: (_) => _save(),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF888888))),
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
