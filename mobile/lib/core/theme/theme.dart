import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

ThemeData buildAppTheme() {
  final base = ThemeData.dark();
  return base.copyWith(
    colorScheme: ColorScheme.dark(
      primary: TrailColors.primary,
      secondary: TrailColors.secondary,
      surface: TrailColors.surface,
      error: TrailColors.error,
    ),
    scaffoldBackgroundColor: TrailColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: TrailColors.background,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: TrailColors.onBackground,
      ),
    ),
    cardTheme: CardThemeData(
      color: TrailColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: TrailColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textTheme: GoogleFonts.spaceGroteskTextTheme(base.textTheme).copyWith(
      displayLarge: const TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 40, fontWeight: FontWeight.w700, color: TrailColors.onBackground),
      displayMedium: const TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 32, fontWeight: FontWeight.w600, color: TrailColors.onBackground),
      titleLarge: const TextStyle(fontFamily: 'SpaceGrotesk', fontSize: 22, fontWeight: FontWeight.w600, color: TrailColors.onBackground),
      bodyLarge: TextStyle(color: TrailColors.onSurface, fontSize: 16),
      bodyMedium: TextStyle(color: TrailColors.onSurface, fontSize: 14),
      bodySmall: TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 12),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: TrailColors.surface,
      selectedItemColor: TrailColors.primary,
      unselectedItemColor: TrailColors.onSurfaceMuted,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      elevation: 0,
    ),
  );
}
