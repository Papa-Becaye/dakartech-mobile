import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Thème Material 3 centralisé de l'application DakarTech.
///
/// Design : moderne, minimaliste, SaaS, beaucoup d'espace blanc,
/// coins légèrement arrondis, ombres discrètes.
abstract final class AppTheme {
  static const ColorScheme colorScheme = ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: AppColors.white,
    primaryContainer: AppColors.primarySoft,
    onPrimaryContainer: AppColors.primary,
    secondary: AppColors.accent,
    onSecondary: AppColors.white,
    secondaryContainer: AppColors.accentSoft,
    onSecondaryContainer: AppColors.accent,
    surface: AppColors.white,
    onSurface: AppColors.dark,
    surfaceContainerHigh: AppColors.white,
    surfaceContainerHighest: AppColors.graySoft,
    error: AppColors.error,
    onError: AppColors.white,
    errorContainer: AppColors.errorSoft,
    onErrorContainer: AppColors.error,
    outline: AppColors.border,
    outlineVariant: AppColors.border,
  );

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamily: 'Geist',
    scaffoldBackgroundColor: AppColors.background,
    textTheme: _buildTextTheme(),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.dark,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Geist',
        fontSize: 20,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: AppColors.dark,
      ),
    ),
    inputDecorationTheme: _buildInputDecorationTheme(),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
    navigationBarTheme: _buildNavigationBarTheme(),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: AppColors.gray),
    ),
    snackBarTheme: _buildSnackBarTheme(),
  );

  static TextTheme _buildTextTheme() {
    return TextTheme(
      displayLarge: AppTextStyles.display,
      displayMedium: AppTextStyles.display.copyWith(fontSize: 34),
      displaySmall: AppTextStyles.display.copyWith(fontSize: 28),
      headlineLarge: AppTextStyles.headline.copyWith(fontSize: 28),
      headlineMedium: AppTextStyles.headline.copyWith(fontSize: 24),
      headlineSmall: AppTextStyles.headline.copyWith(fontSize: 20),
      titleLarge: AppTextStyles.title.copyWith(fontSize: 20),
      titleMedium: AppTextStyles.title.copyWith(fontSize: 16),
      titleSmall: AppTextStyles.title.copyWith(fontSize: 14),
      bodyLarge: AppTextStyles.body,
      bodyMedium: AppTextStyles.body.copyWith(fontSize: 14),
      bodySmall: AppTextStyles.body.copyWith(fontSize: 12),
      labelLarge: AppTextStyles.label.copyWith(fontSize: 14),
      labelMedium: AppTextStyles.label.copyWith(fontSize: 12),
      labelSmall: AppTextStyles.label.copyWith(fontSize: 11),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme() {
    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      labelStyle: AppTextStyles.label.copyWith(color: AppColors.gray),
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.gray),
      prefixIconColor: AppColors.gray,
      suffixIconColor: AppColors.gray,
      enabledBorder: border(AppColors.border),
      focusedBorder: border(AppColors.primary, 2),
      errorBorder: border(AppColors.error),
      focusedErrorBorder: border(AppColors.error, 2),
    );
  }

  static SnackBarThemeData _buildSnackBarTheme() {
    return SnackBarThemeData(
      backgroundColor: AppColors.dark,
      contentTextStyle: AppTextStyles.body.apply(color: AppColors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );
  }

  /// Barre de navigation inférieure : élégante, compacte, mono-couleur.
  ///
  /// L'onglet actif est marqué par une pastille Primary adoucie
  /// (`primarySoft`), l'icône et le libellé passant en Primary. Tous les
  /// autres onglets restent en gris : un seul accent, immédiatement lisible.
  static NavigationBarThemeData _buildNavigationBarTheme() {
    final TextStyle selected = TextStyle(
      fontFamily: 'Geist',
      fontSize: 12,
      height: 1.2,
      fontWeight: FontWeight.w600,
      color: AppColors.primary,
    );
    final TextStyle unselected = selected.copyWith(
      fontWeight: FontWeight.w400,
      color: AppColors.grayLight,
    );

    return NavigationBarThemeData(
      backgroundColor: AppColors.white,
      indicatorColor: AppColors.primarySoft,
      elevation: 0,
      height: 72,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith(
        (Set<WidgetState> states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.grayLight,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (Set<WidgetState> states) =>
            states.contains(WidgetState.selected) ? selected : unselected,
      ),
    );
  }
}
