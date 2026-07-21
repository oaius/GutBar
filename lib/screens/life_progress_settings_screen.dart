import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/life_profile.dart';
import '../services/life_profile_service.dart';
import '../services/theme_preference_service.dart';
import '../theme/app_theme.dart';

class LifeProgressSettingsScreen extends StatefulWidget {
  final LifeProfile? initialProfile;
  final bool showFirstRunContext;

  const LifeProgressSettingsScreen({
    super.key,
    this.initialProfile,
    this.showFirstRunContext = false,
  });

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
    final colors = context.progressColors;
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
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: colors.accent,
              onPrimary: colors.onAccent,
              surface: colors.surface,
              onSurface: colors.textPrimary,
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
    final colors = context.progressColors;
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: colors.border),
    );

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Life Inputs')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showFirstRunContext) ...[
                Text(
                  'This is an estimate, not a prediction.',
                  style: TextStyle(
                    color: colors.textTertiary,
                    fontFamily: 'monospace',
                    fontSize: 13,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 18),
              ],
              const _ThemeModeSwitch(),
              const SizedBox(height: 18),
              Text(
                'Birthdate',
                style: TextStyle(
                  color: colors.textTertiary,
                  fontFamily: 'monospace',
                  letterSpacing: 0,
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
                    color: colors.surfaceAlt,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.border),
                  ),
                  child: Text(
                    _birthdate == null
                        ? 'Select birthdate'
                        : _dateFormat.format(_birthdate!),
                    style: TextStyle(
                      color: _birthdate == null
                          ? colors.textTertiary
                          : colors.textPrimary,
                      fontFamily: 'monospace',
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Life expectancy in years',
                style: TextStyle(
                  color: colors.textTertiary,
                  fontFamily: 'monospace',
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _expectancyController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                cursorColor: colors.accent,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontFamily: 'monospace',
                  letterSpacing: 0,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: colors.surfaceAlt,
                  border: fieldBorder,
                  enabledBorder: fieldBorder,
                  focusedBorder: fieldBorder.copyWith(
                    borderSide: BorderSide(color: colors.textTertiary),
                  ),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
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

class _ThemeModeSwitch extends StatelessWidget {
  const _ThemeModeSwitch();

  @override
  Widget build(BuildContext context) {
    final colors = context.progressColors;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemePreferenceService.themeModeNotifier,
      builder: (context, themeMode, _) {
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Dark mode',
            style: TextStyle(
              color: colors.textPrimary,
              fontFamily: 'monospace',
              letterSpacing: 0,
            ),
          ),
          value: themeMode == ThemeMode.dark,
          onChanged: ThemePreferenceService.setDarkMode,
        );
      },
    );
  }
}
