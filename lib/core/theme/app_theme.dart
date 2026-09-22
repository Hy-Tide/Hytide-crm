// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  // === Light Theme ===
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      error: AppColors.error,
      onError: AppColors.onError,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: const BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceBorder,
        thickness: 1,
        space: 1,
      ),
      // === Global Input Decoration Theme ===
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s12,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
        floatingLabelStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.surfaceBorderSubtle, width: 1),
        ),
        helperStyle: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant),
        errorStyle: AppTypography.labelSmall.copyWith(color: AppColors.error),
        prefixIconColor: AppColors.onSurfaceVariant,
        suffixIconColor: AppColors.onSurfaceVariant,
      ),
      // === Navigation Bar (Mobile Bottom Nav) ===
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 22);
          }
          return const IconThemeData(color: AppColors.onSurfaceVariant, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = AppTypography.labelSmall;
          if (states.contains(WidgetState.selected)) {
            return base.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600);
          }
          return base.copyWith(color: AppColors.onSurfaceVariant);
        }),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.surfaceBorder,
      ),
      // === Chip Theme (Filter Chips) ===
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primaryContainer,
        disabledColor: AppColors.surfaceBorderSubtle,
        labelStyle: AppTypography.labelSmall.copyWith(color: AppColors.onSurface),
        secondaryLabelStyle: AppTypography.labelSmall.copyWith(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r6),
          side: const BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
        elevation: 0,
        pressElevation: 0,
        showCheckmark: true,
        checkmarkColor: AppColors.primary,
      ),
      // === SnackBar Theme ===
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.onSurface,
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.r10)),
      ),
      // === Dialog Theme ===
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.r16)),
        titleTextStyle: AppTypography.headlineSmall,
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
      ),
      // === Popup Menu ===
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r12),
          side: const BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
        labelTextStyle: WidgetStateProperty.all(AppTypography.bodyMedium),
      ),
      // === Segmented Button ===
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: AppColors.surfaceVariant,
          selectedBackgroundColor: AppColors.surface,
          foregroundColor: AppColors.onSurfaceVariant,
          selectedForegroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.surfaceBorder, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.r8)),
          textStyle: AppTypography.labelMedium,
        ),
      ),
    );
  }

  // === Dark Theme ===
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primaryLight,
      onPrimary: AppColors.onPrimary,
      primaryContainer: const Color(0xFF1E3A5F),
      onPrimaryContainer: AppColors.primaryLight,
      secondary: AppColors.secondaryLight,
      onSecondary: AppColors.onSecondary,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.onSurfaceDark,
      error: AppColors.error,
      onError: AppColors.onError,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.onSurfaceDark,
        elevation: 0,
        scrolledUnderElevation: 1,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: const BorderSide(color: AppColors.surfaceBorderDark, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceBorderDark,
        thickness: 1,
        space: 1,
      ),
      // === Global Input Decoration Theme (Dark) ===
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariantDark,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s12,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariantDark),
        labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariantDark),
        floatingLabelStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.primaryLight,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.surfaceBorderDark, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.surfaceBorderDark, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(color: AppColors.surfaceBorderDark.withValues(alpha: 0.5), width: 1),
        ),
        helperStyle: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariantDark),
        errorStyle: AppTypography.labelSmall.copyWith(color: AppColors.error),
        prefixIconColor: AppColors.onSurfaceVariantDark,
        suffixIconColor: AppColors.onSurfaceVariantDark,
      ),
      // === Navigation Bar (Dark) ===
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        indicatorColor: const Color(0xFF1E3A5F),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primaryLight, size: 22);
          }
          return const IconThemeData(color: AppColors.onSurfaceVariantDark, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = AppTypography.labelSmall;
          if (states.contains(WidgetState.selected)) {
            return base.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.w600);
          }
          return base.copyWith(color: AppColors.onSurfaceVariantDark);
        }),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      // === Chip Theme (Dark) ===
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariantDark,
        selectedColor: const Color(0xFF1E3A5F),
        labelStyle: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceDark),
        secondaryLabelStyle: AppTypography.labelSmall.copyWith(color: AppColors.primaryLight),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r6),
          side: const BorderSide(color: AppColors.surfaceBorderDark, width: 1),
        ),
        elevation: 0,
        pressElevation: 0,
        showCheckmark: true,
        checkmarkColor: AppColors.primaryLight,
      ),
      // === SnackBar (Dark) ===
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surfaceVariantDark,
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.r10)),
      ),
      // === Dialog (Dark) ===
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.r16)),
        titleTextStyle: AppTypography.headlineSmall.copyWith(color: AppColors.onSurfaceDark),
        contentTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariantDark),
      ),
      // === Popup Menu (Dark) ===
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r12),
          side: const BorderSide(color: AppColors.surfaceBorderDark, width: 1),
        ),
        labelTextStyle: WidgetStateProperty.all(
          AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceDark),
        ),
      ),
      // === Segmented Button (Dark) ===
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: AppColors.surfaceVariantDark,
          selectedBackgroundColor: AppColors.surfaceDark,
          foregroundColor: AppColors.onSurfaceVariantDark,
          selectedForegroundColor: AppColors.primaryLight,
          side: const BorderSide(color: AppColors.surfaceBorderDark, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.r8)),
          textStyle: AppTypography.labelMedium,
        ),
      ),
    );
  }
}
