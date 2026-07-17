import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/life_profile.dart';
import '../services/life_profile_service.dart';

class LifeProgressSettingsScreen extends StatefulWidget {
  final LifeProfile? initialProfile;

  const LifeProgressSettingsScreen({super.key, this.initialProfile});

  @override
  State<LifeProgressSettingsScreen> createState() =>
      _LifeProgressSettingsScreenState();
}

class _LifeProgressSettingsScreenState
    extends State<LifeProgressSettingsScreen> {
  final _expectancyController = TextEditingController();
  final _dateFormat = DateFormat.yMMMd();
  DateTime? _birthdate;

  @override
  void initState() {
    super.initState();
    _birthdate = widget.initialProfile?.birthdate;
    _expectancyController.text = _formatYears(
      widget.initialProfile?.lifeExpectancyYears ??
          LifeProfileService.defaultExpectancyYears,
    );
  }

  @override
  void dispose() {
    _expectancyController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final firstDate = DateTime(1800);
    final lastDate = DateTime(now.year + 100, 12, 31);
    final candidate = _birthdate ?? DateTime(now.year - 30, now.month, now.day);
    final initialDate = candidate.isBefore(firstDate)
        ? firstDate
        : candidate.isAfter(lastDate)
        ? lastDate
        : candidate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00CC44),
              onPrimary: Colors.black,
              surface: Colors.black,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _birthdate = picked);
    }
  }

  Future<void> _save() async {
    final birthdate = _birthdate;
    if (birthdate == null) return;

    final parsedExpectancy = double.tryParse(_expectancyController.text.trim());
    await LifeProfileService.saveProfile(
      birthdate: birthdate,
      lifeExpectancyYears:
          parsedExpectancy ?? LifeProfileService.defaultExpectancyYears,
    );

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  String _formatYears(double years) {
    if (years.isFinite && years == years.roundToDouble()) {
      return years.toStringAsFixed(0);
    }
    return years.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Life Inputs',
          style: TextStyle(fontFamily: 'monospace'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Birthdate',
                style: TextStyle(
                  color: Color(0xFF888888),
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickBirthdate,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2A2A2A)),
                  ),
                  child: Text(
                    _birthdate == null
                        ? 'Select birthdate'
                        : _dateFormat.format(_birthdate!),
                    style: TextStyle(
                      color: _birthdate == null
                          ? const Color(0xFF888888)
                          : Colors.white,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Life expectancy in years',
                style: TextStyle(
                  color: Color(0xFF888888),
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _expectancyController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF111111),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF888888)),
                  ),
                ),
              ),
              const Spacer(),
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
                      disabledBackgroundColor: const Color(0xFF2A2A2A),
                      disabledForegroundColor: const Color(0xFF888888),
                    ),
                    onPressed: _birthdate == null ? null : _save,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
