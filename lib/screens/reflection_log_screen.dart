import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/reflection_service.dart';
import '../models/reflection.dart';

class ReflectionLogScreen extends StatefulWidget {
  const ReflectionLogScreen({Key? key}) : super(key: key);

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

  Widget _buildGrid() {
    final year = DateTime.now().year;
    final start = DateTime(year, 1, 1);
    final end = DateTime(year, 12, 31);
    final days = end.difference(start).inDays + 1;
    final entries = _items.map((e) => DateTime(e.date.year, e.date.month, e.date.day)).toSet();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(days, (i) {
        final date = start.add(Duration(days: i));
        final filled = entries.contains(DateTime(date.year, date.month, date.day));
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: filled ? const Color(0xFF00CC44) : const Color(0xFF2A2A2A),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMd();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('Reflections', style: TextStyle(fontFamily: 'monospace')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Year overview', style: TextStyle(color: Color(0xFF888888), fontFamily: 'monospace')),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildGrid(),
            ),
            const SizedBox(height: 16),
            const Text('Entries', style: TextStyle(color: Colors.white, fontFamily: 'monospace')),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final r = _items[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(df.format(r.date), style: const TextStyle(color: Color(0xFF888888), fontFamily: 'monospace')),
                    subtitle: Text(r.text, style: const TextStyle(color: Colors.white, fontFamily: 'monospace')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
