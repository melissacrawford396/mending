import 'package:flutter/material.dart';

const mendingInk = Color(0xFF1E2A4A);
const mendingBlue = Color(0xFF2F6FED);
const mendingPaper = Color(0xFFF4F6FB);

/// App colors. Light values stay available as [mendingInk], [mendingBlue],
/// and [mendingPaper] for defaults that have no [BuildContext].
class MendingColors extends ThemeExtension<MendingColors> {
  const MendingColors({
    required this.ink,
    required this.paper,
    required this.blue,
    required this.nav,
    required this.surface,
    required this.figureFill,
    required this.isDark,
  });

  static const light = MendingColors(
    ink: mendingInk,
    paper: mendingPaper,
    blue: mendingBlue,
    nav: Colors.white,
    surface: Colors.white,
    figureFill: Colors.white,
    isDark: false,
  );

  static const dark = MendingColors(
    ink: Color(0xFFE6EAF3),
    paper: Color(0xFF141820),
    blue: Color(0xFF7AA2FF),
    nav: Color(0xFF1C2230),
    surface: Color(0xFF1C2230),
    figureFill: Colors.white,
    isDark: true,
  );

  final Color ink;
  final Color paper;
  final Color blue;
  final Color nav;
  final Color surface;

  /// Body shapes stay light in both themes.
  final Color figureFill;
  final bool isDark;

  static MendingColors of(BuildContext context) {
    return Theme.of(context).extension<MendingColors>() ?? light;
  }

  @override
  MendingColors copyWith({
    Color? ink,
    Color? paper,
    Color? blue,
    Color? nav,
    Color? surface,
    Color? figureFill,
    bool? isDark,
  }) {
    return MendingColors(
      ink: ink ?? this.ink,
      paper: paper ?? this.paper,
      blue: blue ?? this.blue,
      nav: nav ?? this.nav,
      surface: surface ?? this.surface,
      figureFill: figureFill ?? this.figureFill,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  MendingColors lerp(MendingColors? other, double t) {
    if (other == null) return this;
    return MendingColors(
      ink: Color.lerp(ink, other.ink, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      blue: Color.lerp(blue, other.blue, t)!,
      nav: Color.lerp(nav, other.nav, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      figureFill: Color.lerp(figureFill, other.figureFill, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

extension MendingThemeContext on BuildContext {
  MendingColors get mending => MendingColors.of(this);
}

ThemeData mendingTheme(MendingColors colors) {
  final scheme = ColorScheme.fromSeed(
    seedColor: colors.blue,
    brightness: colors.isDark ? Brightness.dark : Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: colors.isDark ? Brightness.dark : Brightness.light,
    colorScheme: scheme,
    extensions: [colors],
    scaffoldBackgroundColor: colors.paper,
    appBarTheme: AppBarTheme(
      backgroundColor: colors.paper,
      foregroundColor: colors.ink,
      elevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colors.nav,
      indicatorColor: colors.blue.withValues(alpha: 0.16),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          color: selected ? colors.blue : colors.ink,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 12,
        );
      }),
    ),
  );
}

String shortDate(DateTime time, {bool use24Hour = true}) {
  final local = time.toLocal();
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final minute = local.minute.toString().padLeft(2, '0');
  final String clock;
  if (use24Hour) {
    clock = '${local.hour.toString().padLeft(2, '0')}:$minute';
  } else {
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final suffix = local.hour < 12 ? 'AM' : 'PM';
    clock = '$hour:$minute $suffix';
  }
  return '${months[local.month - 1]} ${local.day} · $clock';
}
