import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/reflection_service.dart';
import '../models/reflection.dart';
import '../widgets/reflection_year_grid.dart';

class ReflectionLogScreen extends StatefulWidget {
  const ReflectionLogScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final df = DateFormat.yMMMd();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Reflections',
          style: TextStyle(fontFamily: 'monospace'),
        ),
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
        ),
      ),
    );
  }
}
