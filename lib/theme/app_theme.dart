import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

@immutable
class ProgressThemeColors extends ThemeExtension<ProgressThemeColors> {
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color subtleBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color disabled;
  final Color icon;
  final Color accent;
  final Color accentSoft;
  final Color onAccent;
  final Color progressTrack;
  final Color progressTick;

  const ProgressThemeColors({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.subtleBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.disabled,
    required this.icon,
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
    required this.progressTrack,
    required this.progressTick,
  });

  static const dark = ProgressThemeColors(
    background: Color(0xFF000000),
    surface: Color(0xFF000000),
    surfaceAlt: Color(0xFF111111),
    border: Color(0xFF2A2A2A),
    subtleBorder: Color(0xFF141414),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFCCCCCC),
    textTertiary: Color(0xFF888888),
    disabled: Color(0xFF555555),
    icon: Color(0xFFCCCCCC),
    accent: Color(0xFF00CC44),
    accentSoft: Color(0x2033CC66),
    onAccent: Color(0xFF000000),
    progressTrack: Color(0xFF2A2A2A),
    progressTick: Color(0x3DFFFFFF),
  );

  static const light = ProgressThemeColors(
    background: Color(0xFFFAFAFA),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF1F4F2),
    border: Color(0xFFD8DEDA),
    subtleBorder: Color(0xFFE8ECE9),
    textPrimary: Color(0xFF111513),
    textSecondary: Color(0xFF4C5651),
    textTertiary: Color(0xFF69736E),
    disabled: Color(0xFFA1AAA5),
    icon: Color(0xFF4C5651),
    accent: Color(0xFF00A83B),
    accentSoft: Color(0xFFE2F7E8),
    onAccent: Color(0xFF001E0A),
    progressTrack: Color(0xFFDDE4E0),
    progressTick: Color(0x3D000000),
  );

  static ProgressThemeColors of(BuildContext context) {
    final colors = Theme.of(context).extension<ProgressThemeColors>();
    if (colors != null) return colors;
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  @override
  ProgressThemeColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? border,
    Color? subtleBorder,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? disabled,
    Color? icon,
    Color? accent,
    Color? accentSoft,
    Color? onAccent,
    Color? progressTrack,
    Color? progressTick,
  }) {
    return ProgressThemeColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      border: border ?? this.border,
      subtleBorder: subtleBorder ?? this.subtleBorder,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      disabled: disabled ?? this.disabled,
      icon: icon ?? this.icon,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      onAccent: onAccent ?? this.onAccent,
      progressTrack: progressTrack ?? this.progressTrack,
      progressTick: progressTick ?? this.progressTick,
    );
  }

  @override
  ProgressThemeColors lerp(
    ThemeExtension<ProgressThemeColors>? other,
    double t,
  ) {
    if (other is! ProgressThemeColors) return this;

    return ProgressThemeColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      border: Color.lerp(border, other.border, t)!,
      subtleBorder: Color.lerp(subtleBorder, other.subtleBorder, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
      icon: Color.lerp(icon, other.icon, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      progressTrack: Color.lerp(progressTrack, other.progressTrack, t)!,
      progressTick: Color.lerp(progressTick, other.progressTick, t)!,
    );
  }
}

extension ProgressThemeContext on BuildContext {
  ProgressThemeColors get progressColors => ProgressThemeColors.of(this);
}

class AppTheme {
  static ThemeData dark() =>
      _theme(colors: ProgressThemeColors.dark, brightness: Brightness.dark);

  static ThemeData light() =>
      _theme(colors: ProgressThemeColors.light, brightness: Brightness.light);

  static SystemUiOverlayStyle overlayStyleFor(Brightness brightness) {
    final colors = brightness == Brightness.dark
        ? ProgressThemeColors.dark
        : ProgressThemeColors.light;
    final base = brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return base.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: colors.background,
      systemNavigationBarIconBrightness: brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark,
    );
  }

  static ThemeData _theme({
    required ProgressThemeColors colors,
    required Brightness brightness,
  }) {
    final colorScheme = brightness == Brightness.dark
        ? ColorScheme.dark(
            primary: colors.accent,
            onPrimary: colors.onAccent,
            secondary: colors.accent,
            surface: colors.surface,
            onSurface: colors.textPrimary,
          )
        : ColorScheme.light(
            primary: colors.accent,
            onPrimary: colors.onAccent,
            secondary: colors.accent,
            surface: colors.surface,
            onSurface: colors.textPrimary,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      fontFamily: 'monospace',
      extensions: const [],
    ).copyWith(
      extensions: [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: overlayStyleFor(brightness),
        titleTextStyle: TextStyle(
          color: colors.textPrimary,
          fontFamily: 'monospace',
          fontSize: 20,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
        iconTheme: IconThemeData(color: colors.icon),
        actionsIconTheme: IconThemeData(color: colors.icon),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        modalBackgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: colors.textPrimary,
          fontFamily: 'monospace',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        contentTextStyle: TextStyle(
          color: colors.textSecondary,
          fontFamily: 'monospace',
          fontSize: 14,
          letterSpacing: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.disabled)
                ? colors.progressTrack
                : colors.accent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.disabled)
                ? colors.disabled
                : colors.onAccent;
          }),
          overlayColor: WidgetStatePropertyAll(
            colors.onAccent.withValues(alpha: 0.08),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontFamily: 'monospace', letterSpacing: 0),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.disabled)
                ? colors.disabled
                : colors.textTertiary;
          }),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontFamily: 'monospace', letterSpacing: 0),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(colors.icon),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.surfaceAlt,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(
          color: colors.textSecondary,
          fontFamily: 'monospace',
          letterSpacing: 0,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.surfaceAlt,
        contentTextStyle: TextStyle(
          color: colors.textSecondary,
          fontFamily: 'monospace',
          letterSpacing: 0,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? colors.accent
              : colors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? colors.accentSoft
              : colors.progressTrack;
        }),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.accent,
        selectionColor: colors.accentSoft,
        selectionHandleColor: colors.accent,
      ),
    );
  }
}
