import 'package:flutter/material.dart';

const mendingInk = Color(0xFF1E2A4A);
const mendingBlue = Color(0xFF2F6FED);
const mendingPaper = Color(0xFFF4F6FB);

ThemeData mendingTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: mendingBlue);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: mendingPaper,
    appBarTheme: const AppBarTheme(
      backgroundColor: mendingPaper,
      foregroundColor: mendingInk,
      elevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: mendingBlue.withValues(alpha: 0.16),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          color: selected ? mendingBlue : mendingInk,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 12,
        );
      }),
    ),
  );
}

String shortDate(DateTime time) {
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
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${months[local.month - 1]} ${local.day} · $hour:$minute';
}
