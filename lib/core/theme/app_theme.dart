import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central theme system for the Expense Tracker app.
/// Widgets must use Theme.of(context) — no hardcoded colours or text styles.
class AppTheme {
  AppTheme._();

  // ─── Brand Colour Palette ───────────────────────────────────────────────────
  static const Color _primaryColor   = Color(0xFF7C3AED); // vibrant purple
  static const Color _secondaryColor = Color(0xFF6D28D9); // darker purple
  static const Color _errorColor     = Color(0xFFEF4444);

  // ─── Semantic Colours (used directly by widgets) ────────────────────────────
  static const Color incomeColor  = Color(0xFF10B981); // clean green
  static const Color expenseColor = Color(0xFFEF4444); // clean red
  static const Color savingsColor = Color(0xFF42A5F5);

  // Category accent palette
  static const List<Color> categoryColors = [
    Color(0xFF6C63FF), Color(0xFFFF6584), Color(0xFFFFBE0B),
    Color(0xFF4CAF50), Color(0xFF03DAC6), Color(0xFFFF9800),
    Color(0xFF9C27B0), Color(0xFF2196F3),
  ];

  // ─── Dark surface tokens ─────────────────────────────────────────────────────
  static const Color _darkScaffold = Color(0xFF13131F);
  static const Color _darkSurface  = Color(0xFF1E1E2E);
  static const Color _darkElevated = Color(0xFF252538); // cards / bottom nav
  static const Color _darkBorder   = Color(0xFF2A2A3E);
  static const Color _darkSubtle   = Color(0xFF8888AA); // secondary text

  // ─── Light surface tokens ────────────────────────────────────────────────────
  static const Color _lightScaffold = Color(0xFFF5F3FF); // soft lilac background
  static const Color _lightSurface  = Color(0xFFFFFFFF); // pure white cards
  static const Color _lightElevated = Color(0xFFFFFFFF); // elevated white
  static const Color _lightBorder   = Color(0xFFE5E7EB); // subtle grey border
  static const Color _lightSubtle   = Color(0xFF9CA3AF); // neutral grey text

  // ─── Shared text theme builder ───────────────────────────────────────────────
  static TextTheme _buildTextTheme(TextTheme base) {
    return GoogleFonts.interTextTheme(base).copyWith(
      // Page / section titles
      titleLarge:  GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3),
      titleMedium: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700),
      titleSmall:  GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
      // Body copy
      bodyLarge:   GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
      bodyMedium:  GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall:   GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400),
      // Labels (chips, captions, badges)
      labelLarge:  GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
      labelMedium: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
      labelSmall:  GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.4),
      // Display (large amount)
      displayMedium: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: -1.5),
    );
  }

  // ─── Dark Theme ──────────────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamilyFallback: const ['Noto Color Emoji', 'Noto Sans Sinhala'],

        colorScheme: const ColorScheme.dark(
          primary:                _primaryColor,
          onPrimary:              Colors.white,
          secondary:              _secondaryColor,
          onSecondary:            Colors.black,
          error:                  _errorColor,
          surface:                _darkSurface,
          onSurface:              Colors.white,
          onSurfaceVariant:       _darkSubtle,
          surfaceContainerHighest: _darkBorder,
          surfaceContainerLow:    _darkElevated,
          outline:                _darkBorder,
        ),

        scaffoldBackgroundColor: _darkScaffold,
        textTheme: _buildTextTheme(ThemeData.dark().textTheme),

        appBarTheme: AppBarTheme(
          backgroundColor: _darkScaffold,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.inter(
            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),

        cardTheme: CardThemeData(
          color: _darkElevated,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: _darkBorder, width: 1),
          ),
        ),

        listTileTheme: const ListTileThemeData(
          tileColor: Colors.transparent,
          iconColor: _darkSubtle,
          textColor: Colors.white,
        ),

        dividerTheme: const DividerThemeData(
          color: _darkBorder,
          thickness: 1,
          space: 0,
        ),

        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: _darkElevated,
          selectedItemColor: _primaryColor,
          unselectedItemColor: _darkSubtle,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 12),
        ),
        
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: _darkScaffold,
          selectedIconTheme: const IconThemeData(color: Colors.white),
          unselectedIconTheme: const IconThemeData(color: _darkSubtle),
          selectedLabelTextStyle: const TextStyle(color: _primaryColor, fontWeight: FontWeight.w600),
          unselectedLabelTextStyle: const TextStyle(color: _darkSubtle),
          indicatorColor: _primaryColor,
          indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        ),

        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          extendedPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
            elevation: 0,
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _darkSurface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _darkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _primaryColor, width: 2),
          ),
          labelStyle: const TextStyle(color: _darkSubtle),
          hintStyle: const TextStyle(color: Color(0xFF555570)),
        ),

        chipTheme: ChipThemeData(
          backgroundColor: _darkBorder,
          selectedColor: const Color.fromRGBO(124, 58, 237, 0.3),
          labelStyle: GoogleFonts.inter(fontSize: 13),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        ),

        snackBarTheme: SnackBarThemeData(
          backgroundColor: _darkElevated,
          contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
          actionTextColor: _primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
      );

  // ─── Light Theme ─────────────────────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamilyFallback: const ['Noto Color Emoji', 'Noto Sans Sinhala'],

        colorScheme: const ColorScheme.light(
          primary:                _primaryColor,
          onPrimary:              Colors.white,
          secondary:              _secondaryColor,
          onSecondary:            Colors.black,
          error:                  _errorColor,
          surface:                _lightSurface,
          onSurface:              Color(0xFF1A1830),  // deep indigo-black, not pure #000
          onSurfaceVariant:       _lightSubtle,
          surfaceContainerHighest: _lightBorder,
          surfaceContainerLow:    _lightElevated,
          outline:                _lightBorder,
        ),

        scaffoldBackgroundColor: _lightScaffold,
        textTheme: _buildTextTheme(ThemeData.light().textTheme),

        appBarTheme: AppBarTheme(
          backgroundColor: _lightScaffold,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.inter(
            color: const Color(0xFF1A1830), fontSize: 18, fontWeight: FontWeight.w600,
          ),
          iconTheme: const IconThemeData(color: Color(0xFF1A1830)),
        ),

        cardTheme: CardThemeData(
          color: _lightSurface,
          elevation: 8,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: _lightBorder, width: 1),
          ),
          shadowColor: const Color.fromRGBO(124, 58, 237, 0.08),
        ),

        listTileTheme: const ListTileThemeData(
          tileColor: Colors.transparent,
          iconColor: _lightSubtle,
          textColor: Color(0xFF1A1830),
        ),

        dividerTheme: const DividerThemeData(
          color: _lightBorder,
          thickness: 1,
          space: 0,
        ),

        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: _lightSurface,
          selectedItemColor: _primaryColor,
          unselectedItemColor: _lightSubtle,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: 12),
        ),

        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: _lightSurface,
          selectedIconTheme: const IconThemeData(color: Colors.white),
          unselectedIconTheme: const IconThemeData(color: _lightSubtle),
          selectedLabelTextStyle: const TextStyle(color: _primaryColor, fontWeight: FontWeight.w600),
          unselectedLabelTextStyle: const TextStyle(color: _lightSubtle),
          indicatorColor: _primaryColor,
          indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        ),

        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          extendedPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
            elevation: 0,
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _lightElevated,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _lightBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _lightBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _primaryColor, width: 2),
          ),
          labelStyle: const TextStyle(color: _lightSubtle),
          hintStyle: const TextStyle(color: _lightSubtle),
        ),

        chipTheme: ChipThemeData(
          backgroundColor: _lightElevated,
          selectedColor: const Color.fromRGBO(124, 58, 237, 0.15),
          labelStyle: GoogleFonts.poppins(fontSize: 13),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        ),

        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF1A1830),
          contentTextStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
          actionTextColor: _secondaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
      );
  // ─── Unified Theme ─────────────────────────────────────────────────────────────
  static ThemeData getTheme() {
    const primaryColor = Color(0xFF10B981); // Modern Teal/Emerald
    const backgroundColor = Colors.transparent; // Must be transparent for Aurora
    final surfaceColor = Colors.white.withOpacity(0.75); // Glassmorphic surface
    const errorColor = Color(0xFFF43F5E);
    const textColor = Color(0xFF1E293B);
    const textLightColor = Color(0xFF64748B);

    final baseTextTheme = GoogleFonts.poppinsTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        surface: surfaceColor,
        error: errorColor,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(color: textColor),
        displayMedium: baseTextTheme.displayMedium?.copyWith(color: textColor),
        displaySmall: baseTextTheme.displaySmall?.copyWith(color: textColor),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(color: textColor),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(color: textColor),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(color: textColor),
        titleLarge: baseTextTheme.titleLarge?.copyWith(color: textColor),
        titleMedium: baseTextTheme.titleMedium?.copyWith(color: textColor),
        titleSmall: baseTextTheme.titleSmall?.copyWith(color: textColor),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: textColor),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: textColor),
        bodySmall: baseTextTheme.bodySmall?.copyWith(color: textLightColor),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: textColor),
        titleTextStyle: GoogleFonts.poppins(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        hintStyle: const TextStyle(color: textLightColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      iconTheme: const IconThemeData(
        color: textColor,
      ),
    );
  }
}
