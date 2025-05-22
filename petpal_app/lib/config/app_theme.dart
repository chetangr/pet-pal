import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App color palette
class AppColors {
  // Primary
  static const Color primary = Color(0xFF4A89DC);
  static const Color primaryLight = Color(0xFF6FA1EC);
  static const Color primaryDark = Color(0xFF3469B2);
  
  // Secondary
  static const Color secondary = Color(0xFF8CC152);
  static const Color secondaryLight = Color(0xFFA5D57B);
  static const Color secondaryDark = Color(0xFF6C9D39);
  
  // Accent
  static const Color accent = Color(0xFFF6BB42);
  static const Color accentLight = Color(0xFFF8CB6B);
  static const Color accentDark = Color(0xFFD19A2C);
  
  // Neutral
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFE6EBF5);
  
  // Text
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textTertiary = Color(0xFFBDC3C7);
  
  // Status
  static const Color success = Color(0xFF2ECC71);
  static const Color error = Color(0xFFE9573F);
  static const Color warning = Color(0xFFF6BB42);
  static const Color info = Color(0xFF5D9CEC);
  
  // Dark theme
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C);
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFFBBBBBB);
}

/// App typography
class AppTypography {
  static const String fontFamilyHeadline = 'Montserrat';
  static const String fontFamilyBody = 'Inter';
  
  static const TextTheme lightTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: fontFamilyHeadline,
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),
    displayMedium: TextStyle(
      fontFamily: fontFamilyHeadline,
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),
    displaySmall: TextStyle(
      fontFamily: fontFamilyHeadline,
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    headlineLarge: TextStyle(
      fontFamily: fontFamilyHeadline,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    headlineMedium: TextStyle(
      fontFamily: fontFamilyHeadline,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    headlineSmall: TextStyle(
      fontFamily: fontFamilyHeadline,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    titleLarge: TextStyle(
      fontFamily: fontFamilyHeadline,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    titleMedium: TextStyle(
      fontFamily: fontFamilyHeadline,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    titleSmall: TextStyle(
      fontFamily: fontFamilyHeadline,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
    ),
    bodyLarge: TextStyle(
      fontFamily: fontFamilyBody,
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: AppColors.textPrimary,
    ),
    bodyMedium: TextStyle(
      fontFamily: fontFamilyBody,
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: AppColors.textPrimary,
    ),
    bodySmall: TextStyle(
      fontFamily: fontFamilyBody,
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: AppColors.textSecondary,
    ),
    labelLarge: TextStyle(
      fontFamily: fontFamilyBody,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
    ),
    labelMedium: TextStyle(
      fontFamily: fontFamilyBody,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
    ),
    labelSmall: TextStyle(
      fontFamily: fontFamilyBody,
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
    ),
  );
  
  static const TextTheme darkTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontFamily: fontFamilyHeadline,
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: AppColors.darkTextPrimary,
    ),
    displayMedium: TextStyle(
      fontFamily: fontFamilyHeadline,
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: AppColors.darkTextPrimary,
    ),
    displaySmall: TextStyle(
      fontFamily: fontFamilyHeadline,
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: AppColors.darkTextPrimary,
    ),
    headlineLarge: TextStyle(
      fontFamily: fontFamilyHeadline,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: AppColors.darkTextPrimary,
    ),
    headlineMedium: TextStyle(
      fontFamily: fontFamilyHeadline,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.darkTextPrimary,
    ),
    headlineSmall: TextStyle(
      fontFamily: fontFamilyHeadline,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.darkTextPrimary,
    ),
    titleLarge: TextStyle(
      fontFamily: fontFamilyHeadline,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.darkTextPrimary,
    ),
    titleMedium: TextStyle(
      fontFamily: fontFamilyHeadline,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.darkTextPrimary,
    ),
    titleSmall: TextStyle(
      fontFamily: fontFamilyHeadline,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.darkTextSecondary,
    ),
    bodyLarge: TextStyle(
      fontFamily: fontFamilyBody,
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: AppColors.darkTextPrimary,
    ),
    bodyMedium: TextStyle(
      fontFamily: fontFamilyBody,
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: AppColors.darkTextPrimary,
    ),
    bodySmall: TextStyle(
      fontFamily: fontFamilyBody,
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: AppColors.darkTextSecondary,
    ),
    labelLarge: TextStyle(
      fontFamily: fontFamilyBody,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.darkTextPrimary,
    ),
    labelMedium: TextStyle(
      fontFamily: fontFamilyBody,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.darkTextPrimary,
    ),
    labelSmall: TextStyle(
      fontFamily: fontFamilyBody,
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: AppColors.darkTextSecondary,
    ),
  );
}

/// App theme
class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.secondaryLight,
      onSecondaryContainer: Colors.white,
      tertiary: AppColors.accent,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.accentLight,
      onTertiaryContainer: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.error.withOpacity(0.2),
      onErrorContainer: AppColors.error,
      background: AppColors.background,
      onBackground: AppColors.textPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceVariant: AppColors.surfaceVariant,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.textTertiary,
      shadow: Colors.black.withOpacity(0.1),
      inverseSurface: AppColors.textPrimary,
      onInverseSurface: AppColors.surface,
      inversePrimary: AppColors.primaryLight,
      surfaceTint: AppColors.primary.withOpacity(0.05),
    ),
    textTheme: AppTypography.lightTextTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    cardTheme: CardTheme(
      color: AppColors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      hintStyle: AppTypography.lightTextTheme.bodyMedium?.copyWith(
        color: AppColors.textSecondary,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceVariant,
      labelStyle: AppTypography.lightTextTheme.labelMedium,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.surfaceVariant,
      thickness: 1,
      space: 1,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.primary;
        }
        return AppColors.surfaceVariant;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.primary.withOpacity(0.5);
        }
        return AppColors.textTertiary.withOpacity(0.5);
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.primary;
        }
        return null;
      }),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.primary;
        }
        return null;
      }),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: AppColors.surface,
      elevation: 24,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
  
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryDark,
      onPrimaryContainer: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.secondaryDark,
      onSecondaryContainer: Colors.white,
      tertiary: AppColors.accent,
      onTertiary: Colors.white,
      tertiaryContainer: AppColors.accentDark,
      onTertiaryContainer: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.error.withOpacity(0.2),
      onErrorContainer: AppColors.error,
      background: AppColors.darkBackground,
      onBackground: AppColors.darkTextPrimary,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      surfaceVariant: AppColors.darkSurfaceVariant,
      onSurfaceVariant: AppColors.darkTextSecondary,
      outline: AppColors.darkTextSecondary,
      shadow: Colors.black.withOpacity(0.3),
      inverseSurface: AppColors.darkTextPrimary,
      onInverseSurface: AppColors.darkSurface,
      inversePrimary: AppColors.primaryDark,
      surfaceTint: AppColors.primary.withOpacity(0.1),
    ),
    textTheme: AppTypography.darkTextTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkSurface,
      foregroundColor: AppColors.darkTextPrimary,
      elevation: 0,
      centerTitle: true,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.darkTextSecondary,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    cardTheme: CardTheme(
      color: AppColors.darkSurface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      hintStyle: AppTypography.darkTextTheme.bodyMedium?.copyWith(
        color: AppColors.darkTextSecondary,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.darkSurfaceVariant,
      labelStyle: AppTypography.darkTextTheme.labelMedium,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.darkSurfaceVariant,
      thickness: 1,
      space: 1,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.primary;
        }
        return AppColors.darkSurfaceVariant;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.primary.withOpacity(0.5);
        }
        return AppColors.darkTextSecondary.withOpacity(0.5);
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.primary;
        }
        return null;
      }),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return AppColors.primary;
        }
        return null;
      }),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: AppColors.darkSurface,
      elevation: 24,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}

// Provider for theme mode
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);