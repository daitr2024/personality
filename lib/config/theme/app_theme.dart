import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Curated Color Palettes ──────────────────────────────────
  static const Map<String, Color> seedColors = {
    'blue': Color(0xFF4A90D9),
    'green': Color(0xFF2ECC71),
    'purple': Color(0xFF9B59B6),
    'orange': Color(0xFFFF8C42),
    'red': Color(0xFFE74C3C),
  };

  // ─── Semantic Colors (used across both light & dark) ─────────
  static const Color taskColor = Color(0xFFFF8C42); // Warm Amber
  static const Color eventColor = Color(0xFF4A90D9); // Royal Blue
  static const Color noteColor = Color(0xFF9B59B6); // Amethyst
  static const Color completedColor = Color(0xFF2ECC71); // Emerald
  static const Color urgentColor = Color(0xFFE74C3C); // Crimson
  static const Color incomeColor = Color(0xFF2ECC71); // Emerald
  static const Color expenseColor = Color(0xFFE74C3C); // Crimson

  // ─── Light Theme ─────────────────────────────────────────────
  static ThemeData lightTheme(Color seedColor) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      surface: const Color(0xFFF8FAFC),
      onSurface: const Color(0xFF1E293B),
      surfaceContainerHighest: Colors.white,
    );

    final textTheme = _buildTextTheme(Brightness.light);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,

      // ── AppBar ──
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: GoogleFonts.outfit(
          color: colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ── Cards ──
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Elevated Buttons ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Text Buttons ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Input Decoration ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: GoogleFonts.outfit(
          color: colorScheme.onSurface.withValues(alpha: 0.4),
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.outfit(
          color: colorScheme.onSurface.withValues(alpha: 0.6),
          fontSize: 14,
        ),
      ),

      // ── Bottom Navigation ──
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            );
          }
          return GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.primary, size: 24);
          }
          return IconThemeData(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
            size: 24,
          );
        }),
      ),

      // ── Bottom Sheet ──
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        dragHandleColor: colorScheme.onSurface.withValues(alpha: 0.15),
        showDragHandle: true,
      ),

      // ── Dialog ──
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.outfit(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // ── Snackbar ──
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentTextStyle: GoogleFonts.outfit(
          color: colorScheme.onInverseSurface,
          fontSize: 14,
        ),
      ),

      // ── Divider ──
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        thickness: 1,
      ),

      // ── Chip ──
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primary.withValues(alpha: 0.15),
        labelStyle: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide.none,
      ),

      // ── Switch ──
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.primary;
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withValues(alpha: 0.3);
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),

      // ── ListTile ──
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        subtitleTextStyle: GoogleFonts.outfit(
          fontSize: 13,
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),

      // ── Floating Action Button ──
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // ─── Dark Theme ──────────────────────────────────────────────
  static ThemeData darkTheme(Color seedColor) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      surface: const Color(0xFF0F172A),
      onSurface: const Color(0xFFE2E8F0),
      surfaceContainerHighest: const Color(0xFF1E293B),
    );

    final textTheme = _buildTextTheme(Brightness.dark);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,

      // ── AppBar ──
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: GoogleFonts.outfit(
          color: colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ── Cards ──
      cardTheme: CardThemeData(
        color: const Color(0xFF1E293B),
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Elevated Buttons ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Text Buttons ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Input Decoration ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: GoogleFonts.outfit(
          color: colorScheme.onSurface.withValues(alpha: 0.4),
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.outfit(
          color: colorScheme.onSurface.withValues(alpha: 0.6),
          fontSize: 14,
        ),
      ),

      // ── Bottom Navigation ──
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            );
          }
          return GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.primary, size: 24);
          }
          return IconThemeData(
            color: colorScheme.onSurface.withValues(alpha: 0.5),
            size: 24,
          );
        }),
      ),

      // ── Bottom Sheet ──
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: const Color(0xFF1E293B),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        dragHandleColor: colorScheme.onSurface.withValues(alpha: 0.2),
        showDragHandle: true,
      ),

      // ── Dialog ──
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.outfit(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // ── Snackbar ──
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentTextStyle: GoogleFonts.outfit(
          color: colorScheme.onInverseSurface,
          fontSize: 14,
        ),
      ),

      // ── Divider ──
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.15),
        thickness: 1,
      ),

      // ── Chip ──
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primary.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide.none,
      ),

      // ── Switch ──
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colorScheme.primary;
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withValues(alpha: 0.3);
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),

      // ── ListTile ──
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        subtitleTextStyle: GoogleFonts.outfit(
          fontSize: 13,
          color: colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),

      // ── Floating Action Button ──
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // ─── Shared Text Theme ───────────────────────────────────────
  static TextTheme _buildTextTheme(Brightness brightness) {
    final baseColor = brightness == Brightness.light
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);

    return TextTheme(
      displayLarge: GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: baseColor,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: baseColor,
        letterSpacing: -0.5,
      ),
      headlineLarge: GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: baseColor,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      headlineSmall: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      titleLarge: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      titleMedium: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      titleSmall: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      bodyLarge: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: baseColor.withValues(alpha: 0.87),
      ),
      bodyMedium: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: baseColor.withValues(alpha: 0.87),
      ),
      bodySmall: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: baseColor.withValues(alpha: 0.6),
      ),
      labelLarge: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: baseColor,
      ),
      labelMedium: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: baseColor.withValues(alpha: 0.7),
      ),
      labelSmall: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: baseColor.withValues(alpha: 0.6),
      ),
    );
  }
}
