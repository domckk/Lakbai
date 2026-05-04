import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

ThemeData buildAppTheme() {
  final base = GoogleFonts.spaceGroteskTextTheme(ThemeData.light().textTheme);

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: TrailColors.primary,
      onPrimary: Colors.white,
      secondary: TrailColors.secondary,
      onSecondary: Colors.white,
      surface: TrailColors.surface,
      onSurface: TrailColors.onSurface,
      error: TrailColors.error,
      onError: Colors.white,
      outline: TrailColors.peach,
    ),
    scaffoldBackgroundColor: TrailColors.background,

    appBarTheme: AppBarTheme(
      backgroundColor: TrailColors.background,
      foregroundColor: TrailColors.onBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: const TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: TrailColors.onBackground,
      ),
      iconTheme: const IconThemeData(color: TrailColors.onBackground),
    ),

    cardTheme: CardThemeData(
      color: TrailColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: TrailColors.peach),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: TrailColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3),
        elevation: 0,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: TrailColors.primary,
        side: const BorderSide(color: TrailColors.primary, width: 1.5),
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: TrailColors.peach.withOpacity(0.25),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: TrailColors.peach),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: TrailColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: TrailColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: TrailColors.error, width: 2),
      ),
      labelStyle: const TextStyle(color: TrailColors.onSurfaceMuted),
      hintStyle: const TextStyle(color: TrailColors.onSurfaceMuted),
      prefixIconColor: TrailColors.onSurfaceMuted,
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: TrailColors.surface,
      indicatorColor: TrailColors.primary.withOpacity(0.12),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(color: TrailColors.primary, fontWeight: FontWeight.w700, fontSize: 11, fontFamily: 'SpaceGrotesk');
        }
        return const TextStyle(color: TrailColors.onSurfaceMuted, fontSize: 11, fontFamily: 'SpaceGrotesk');
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return const IconThemeData(color: TrailColors.primary);
        return const IconThemeData(color: TrailColors.onSurfaceMuted);
      }),
    ),

    tabBarTheme: const TabBarThemeData(
      indicatorColor: TrailColors.primary,
      labelColor: TrailColors.primary,
      unselectedLabelColor: TrailColors.onSurfaceMuted,
      dividerColor: TrailColors.peach,
    ),

    dividerColor: TrailColors.peach,
    dividerTheme: const DividerThemeData(color: TrailColors.peach, space: 0),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: TrailColors.primary),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: TrailColors.brown,
      contentTextStyle: const TextStyle(color: Colors.white, fontFamily: 'SpaceGrotesk', fontSize: 14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: TrailColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),

    textTheme: base.copyWith(
      displayLarge:  base.displayLarge?.copyWith(fontSize: 40, fontWeight: FontWeight.w700, color: TrailColors.onBackground),
      displayMedium: base.displayMedium?.copyWith(fontSize: 32, fontWeight: FontWeight.w600, color: TrailColors.onBackground),
      titleLarge:    base.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.w700, color: TrailColors.onBackground),
      titleMedium:   base.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: TrailColors.onBackground),
      bodyLarge:     base.bodyLarge?.copyWith(color: TrailColors.onSurface, fontSize: 16),
      bodyMedium:    base.bodyMedium?.copyWith(color: TrailColors.onSurface, fontSize: 14),
      bodySmall:     base.bodySmall?.copyWith(color: TrailColors.onSurfaceMuted, fontSize: 12),
    ),
  );
}
