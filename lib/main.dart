import 'dart:async';
import 'package:flutter/material.dart';

import 'models/reflection.dart';
import 'services/reflection_service.dart';
import 'services/life_profile_service.dart';
import 'services/onboarding_service.dart';
import 'services/year_progress_home_widget_service.dart';
import 'widgets/reflection_entry_sheet.dart';
import 'widgets/progress_bar_widget.dart';
import 'screens/life_progress_screen.dart';
import 'screens/reflection_log_screen.dart';
import 'utils/year_progress.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ReflectionService.init();
  await LifeProfileService.init();
  await OnboardingService.init();
  await YearProgressHomeWidgetService.initialize();
  runApp(const MyApp());
}

final appNavigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  StreamSubscription<dynamic>? _widgetLaunchSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _widgetLaunchSubscription =
        YearProgressHomeWidgetService.listenForWidgetLaunches(() {
          appNavigatorKey.currentState?.popUntil((route) => route.isFirst);
        });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(YearProgressHomeWidgetService.updateWidgetData());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _widgetLaunchSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Legder',
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: const YearProgressWidget(),
      ),
    );
  }
}

class YearProgressWidget extends StatefulWidget {
  const YearProgressWidget({super.key});

  @override
  State<YearProgressWidget> createState() => _YearProgressWidgetState();
}

class _YearProgressWidgetState extends State<YearProgressWidget> {
  static const _introTextStyle = TextStyle(
    fontFamily: 'monospace',
    fontSize: 13,
    color: Color(0xFF888888),
  );

  late Timer _timer;
  late DateTime _now;
  late bool _showYearIntro;
  bool _dismissingYearIntro = false;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _showYearIntro = !OnboardingService.hasSeenYearIntro;
    // Refresh every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDate() {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final month = months[_now.month - 1];
    final day = _now.day;
    final hour = _now.hour.toString().padLeft(2, '0');
    final minute = _now.minute.toString().padLeft(2, '0');
    return '$month $day, $hour:$minute';
  }

  Future<void> _dismissYearIntro() async {
    if (!_showYearIntro || _dismissingYearIntro) return;

    setState(() => _showYearIntro = false);
    _dismissingYearIntro = true;
    await OnboardingService.markYearIntroSeen();
    _dismissingYearIntro = false;
  }

  @override
  Widget build(BuildContext context) {
    final progress = yearProgress(_now);
    final percent = (progress * 100).toStringAsFixed(0);
    final todayReflection = ReflectionService.getToday();

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        _dismissYearIntro();
      },
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildProgressPanel(
                progress: progress,
                percent: percent,
                todayReflection: todayReflection,
              ),
            ),
          ),
          if (_showYearIntro)
            const SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Text(
                  'No streaks. Just the number.',
                  style: _introTextStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressPanel({
    required double progress,
    required String percent,
    required Reflection? todayReflection,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProgressBarWidget(
            percentage: progress,
            primaryText: '$percent% of ${_now.year} has passed',
            secondaryText: '${daysLeftInYear(_now)} days left in ${_now.year}',
            detailText: _formatDate(),
            tickPositions: const [0.25, 0.5, 0.75],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => AnimatedPadding(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.viewInsetsOf(context).bottom,
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                          ),
                          child: ReflectionEntrySheet(
                            onSaved: () => setState(() {}),
                          ),
                        ),
                      ),
                    );
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: todayReflection == null
                          ? const Color(0xFF111111)
                          : const Color(0x2033CC66),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          todayReflection == null
                              ? Icons.edit
                              : Icons.check_circle,
                          color: todayReflection == null
                              ? const Color(0xFF888888)
                              : const Color(0xFF00CC44),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            todayReflection == null
                                ? 'One thing you did today'
                                : todayReflection.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              color: Color(0xFFCCCCCC),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LifeProgressScreen(),
                    ),
                  );
                  setState(() {});
                },
                icon: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF888888),
                ),
                tooltip: 'Life progress',
              ),
              IconButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ReflectionLogScreen(),
                    ),
                  );
                  setState(() {});
                },
                icon: const Icon(Icons.history, color: Color(0xFF888888)),
                tooltip: 'View reflections',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
