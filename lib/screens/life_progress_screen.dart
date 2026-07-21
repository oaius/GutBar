import 'dart:async';

import 'package:flutter/material.dart';

import '../models/life_profile.dart';
import '../services/life_profile_service.dart';
import '../services/onboarding_service.dart';
import '../services/theme_preference_service.dart';
import '../theme/app_theme.dart';
import '../utils/life_progress.dart';
import '../widgets/progress_bar_widget.dart';
import 'life_progress_settings_screen.dart';

class LifeProgressScreen extends StatefulWidget {
  const LifeProgressScreen({super.key});

  @override
  State<LifeProgressScreen> createState() => _LifeProgressScreenState();
}

class _LifeProgressScreenState extends State<LifeProgressScreen> {
  static const _decadeTicks = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9];

  late Timer _timer;
  late DateTime _now;
  bool _openedFirstRunPrompt = false;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() => _now = DateTime.now());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openSettingsIfNeeded();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _openSettingsIfNeeded() async {
    if (!mounted ||
        _openedFirstRunPrompt ||
        OnboardingService.hasSeenLifeInputsPrompt ||
        LifeProfileService.profile != null) {
      return;
    }

    _openedFirstRunPrompt = true;
    await OnboardingService.markLifeInputsPromptSeen();
    if (!mounted) return;

    await _openSettings(showFirstRunContext: true);
  }

  Future<void> _openSettings({bool showFirstRunContext = false}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LifeProgressSettingsScreen(
          initialProfile: LifeProfileService.profile,
          showFirstRunContext: showFirstRunContext,
        ),
      ),
    );

    if (!mounted) return;
    if (saved == true) {
      setState(() => _now = DateTime.now());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.progressColors;
    final profile = LifeProfileService.profile;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Life Progress'),
        actions: [
          IconButton(
            onPressed: ThemePreferenceService.toggleTheme,
            icon: Icon(
              ThemePreferenceService.isDarkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              color: colors.icon,
            ),
            tooltip: ThemePreferenceService.isDarkMode
                ? 'Light mode'
                : 'Dark mode',
          ),
          IconButton(
            onPressed: _openSettings,
            icon: Icon(Icons.settings, color: colors.icon),
            tooltip: 'Edit inputs',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: profile == null
                ? _MissingLifeInputs(onOpenSettings: _openSettings)
                : _LifeProgressReadout(profile: profile, now: _now),
          ),
        ),
      ),
    );
  }
}

class _LifeProgressReadout extends StatelessWidget {
  final LifeProfile profile;
  final DateTime now;

  const _LifeProgressReadout({required this.profile, required this.now});

  @override
  Widget build(BuildContext context) {
    final progress = lifeProgress(
      birthdate: profile.birthdate,
      lifeExpectancyYears: profile.lifeExpectancyYears,
      today: now,
    );
    final percent = (progress.percentage * 100).toStringAsFixed(0);
    final detailText = progress.expectancyExceeded
        ? 'expectancy exceeded - based on your inputs - not a prediction'
        : 'based on your inputs - not a prediction';

    return ProgressBarWidget(
      percentage: progress.percentage,
      primaryText: '$percent% of your life has passed',
      secondaryText: '~${progress.daysRemaining} days remaining',
      detailText: detailText,
      tickPositions: _LifeProgressScreenState._decadeTicks,
    );
  }
}

class _MissingLifeInputs extends StatelessWidget {
  final VoidCallback onOpenSettings;

  const _MissingLifeInputs({required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    final colors = context.progressColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'No life inputs saved',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: onOpenSettings,
          child: const Text('Set inputs'),
        ),
      ],
    );
  }
}
