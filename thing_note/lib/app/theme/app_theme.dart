import 'package:flutter/material.dart';

class AppTheme {
  static const String _fontFamily = 'NotoSansSC';

  static const Color _zinc50 = Color(0xFFFAFAFA);
  static const Color _zinc100 = Color(0xFFF4F4F5);
  static const Color _zinc200 = Color(0xFFE4E4E7);
  static const Color _zinc300 = Color(0xFFD4D4D8);
  static const Color _zinc400 = Color(0xFFA1A1AA);
  static const Color _zinc500 = Color(0xFF71717A);
  static const Color _zinc600 = Color(0xFF52525B);
  static const Color _zinc700 = Color(0xFF3F3F46);
  static const Color _zinc800 = Color(0xFF27272A);
  static const Color _zinc900 = Color(0xFF18181B);
  static const Color _zinc950 = Color(0xFF09090B);

  static ThemeData get lightTheme => _buildTheme(_buildLightScheme(), Brightness.light);
  static ThemeData get darkTheme => _buildTheme(_buildDarkScheme(), Brightness.dark);

  static ColorScheme _buildLightScheme() {
    return ColorScheme(
      brightness: Brightness.light,
      primary: _zinc900,
      onPrimary: Colors.white,
      primaryContainer: _zinc100,
      onPrimaryContainer: _zinc900,
      secondary: _zinc700,
      onSecondary: Colors.white,
      secondaryContainer: _zinc100,
      onSecondaryContainer: _zinc700,
      tertiary: _zinc500,
      onTertiary: Colors.white,
      tertiaryContainer: _zinc100,
      onTertiaryContainer: _zinc600,
      error: Color(0xFFDC2626),
      onError: Colors.white,
      errorContainer: Color(0xFFFEE2E2),
      onErrorContainer: Color(0xFF991B1B),
      surface: Colors.white,
      onSurface: _zinc900,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: _zinc50,
      surfaceContainer: _zinc100,
      surfaceContainerHigh: _zinc200,
      surfaceContainerHighest: _zinc200,
      onSurfaceVariant: _zinc600,
      outline: _zinc300,
      outlineVariant: _zinc200,
      inverseSurface: _zinc900,
      onInverseSurface: _zinc100,
      shadow: Colors.black.withOpacity(0.1),
      scrim: _zinc950,
    );
  }

  static ColorScheme _buildDarkScheme() {
    return ColorScheme(
      brightness: Brightness.dark,
      primary: _zinc100,
      onPrimary: _zinc900,
      primaryContainer: _zinc800,
      onPrimaryContainer: _zinc100,
      secondary: _zinc300,
      onSecondary: _zinc900,
      secondaryContainer: _zinc700,
      onSecondaryContainer: _zinc200,
      tertiary: _zinc400,
      onTertiary: _zinc900,
      tertiaryContainer: _zinc700,
      onTertiaryContainer: _zinc300,
      error: Color(0xFFFCA5A5),
      onError: Color(0xFF7F1D1D),
      errorContainer: Color(0xFF991B1B),
      onErrorContainer: Color(0xFFFEE2E2),
      surface: _zinc950,
      onSurface: _zinc100,
      surfaceContainerLowest: _zinc950,
      surfaceContainerLow: _zinc900,
      surfaceContainer: _zinc900,
      surfaceContainerHigh: _zinc800,
      surfaceContainerHighest: _zinc800,
      onSurfaceVariant: _zinc400,
      outline: _zinc600,
      outlineVariant: _zinc800,
      inverseSurface: _zinc100,
      onInverseSurface: _zinc900,
      shadow: Colors.black.withOpacity(0.3),
      scrim: _zinc950,
    );
  }

  static ThemeData _buildTheme(ColorScheme colorScheme, Brightness brightness) {
    final isLight = brightness == Brightness.light;

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      fontFamily: _fontFamily,
      brightness: brightness,

      textTheme: _buildTextTheme(colorScheme),

      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: isLight ? 0.5 : 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
          letterSpacing: 0.5,
        ),
      ),

      cardTheme: CardTheme(
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        clipBehavior: Clip.antiAlias,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.w500,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          side: BorderSide(
            color: colorScheme.outline,
          ),
          textStyle: TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        focusElevation: 4,
        hoverElevation: 4,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 1.5,
          ),
        ),
        labelStyle: TextStyle(
          fontFamily: _fontFamily,
          color: colorScheme.onSurfaceVariant,
          fontSize: 14,
        ),
        hintStyle: TextStyle(
          fontFamily: _fontFamily,
          color: colorScheme.onSurfaceVariant,
          fontSize: 14,
        ),
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 0,
      ),

      dialogTheme: DialogTheme(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        backgroundColor: colorScheme.onSurface,
        contentTextStyle: TextStyle(
          fontFamily: _fontFamily,
          color: colorScheme.surface,
          fontSize: 14,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primary,
        labelStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return isLight ? _zinc100 : _zinc400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return isLight ? _zinc300 : _zinc600;
        }),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: colorScheme.outlineVariant,
          ),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHighest,
      ),

      iconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant,
        size: 24,
      ),

      primaryIconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: 24,
      ),
    );
  }

  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
        height: 1.25,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
        height: 1.29,
        letterSpacing: -0.25,
      ),
      displaySmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        height: 1.33,
      ),
      headlineLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        height: 1.36,
      ),
      headlineMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        height: 1.4,
      ),
      headlineSmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        height: 1.44,
      ),
      titleLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
        height: 1.44,
        letterSpacing: 0.15,
      ),
      titleMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
        height: 1.5,
        letterSpacing: 0.15,
      ),
      titleSmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurfaceVariant,
        height: 1.43,
        letterSpacing: 0.1,
      ),
      bodyLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
        height: 1.5,
        letterSpacing: 0.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurface,
        height: 1.43,
        letterSpacing: 0.25,
      ),
      bodySmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: colorScheme.onSurfaceVariant,
        height: 1.33,
        letterSpacing: 0.4,
      ),
      labelLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurface,
        height: 1.43,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurfaceVariant,
        height: 1.33,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurfaceVariant,
        height: 1.45,
        letterSpacing: 0.5,
      ),
    );
  }

  static BoxDecoration softCardDecoration(BuildContext context, {Color? color}) {
    final cs = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    return BoxDecoration(
      color: color ?? (isLight ? Colors.white : cs.surfaceContainerHigh),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: cs.outlineVariant,
        width: 1,
      ),
    );
  }

  static BoxDecoration sectionDecoration(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: cs.outlineVariant,
        width: 1,
      ),
    );
  }
}
