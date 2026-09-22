// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // === Brand Colors (Modern SaaS Blue/Indigo) ===
  static const Color primary = Color(0xFF2563EB); // Blue-600
  static const Color primaryLight = Color(0xFF3B82F6); // Blue-500
  static const Color primaryDark = Color(0xFF1D4ED8); // Blue-700
  static const Color primaryContainer = Color(0xFFEFF6FF); // Blue-50
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF1E3A8A); // Blue-900

  // === Secondary ===
  static const Color secondary = Color(0xFF4F46E5); // Indigo-600
  static const Color secondaryLight = Color(0xFF6366F1); // Indigo-500
  static const Color secondaryContainer = Color(0xFFEEF2FF); // Indigo-50
  static const Color onSecondary = Color(0xFFFFFFFF);

  // === Neutral / Light Surface ===
  static const Color background = Color(0xFFF8FAFC); // Slate-50
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Slate-100
  static const Color surfaceBorder = Color(0xFFE2E8F0); // Slate-200
  static const Color surfaceBorderSubtle = Color(0xFFF1F5F9); // Slate-100
  static const Color onBackground = Color(0xFF0F172A); // Slate-900
  static const Color onSurface = Color(0xFF1E293B); // Slate-800
  static const Color onSurfaceVariant = Color(0xFF64748B); // Slate-500
  static const Color textMuted = Color(0xFF94A3B8); // Slate-400
  static const Color surfaceContainer = Color(0xFFF1F5F9); // Slate-100

  // === Dark Theme Surfaces ===
  static const Color backgroundDark = Color(0xFF0B0F19); // Deep Slate
  static const Color surfaceDark = Color(0xFF131B2E); // Elevated Slate
  static const Color surfaceVariantDark = Color(0xFF1E293B); // Slate-800
  static const Color surfaceContainerDark = Color(0xFF1E293B); // Slate-800
  static const Color surfaceBorderDark = Color(0xFF2E3A52); // Subtle border
  static const Color onBackgroundDark = Color(0xFFF8FAFC);
  static const Color onSurfaceDark = Color(0xFFF1F5F9);
  static const Color onSurfaceVariantDark = Color(0xFF94A3B8);

  // === Status Colors ===
  static const Color success = Color(0xFF16A34A); // Green-600
  static const Color successLight = Color(0xFFF0FDF4); // Green-50
  static const Color successDark = Color(0xFF15803D);
  static const Color successContainer = Color(0xFFDCFCE7); // Green-100
  static const Color onSuccess = Color(0xFFFFFFFF);

  static const Color warning = Color(0xFFD97706); // Amber-600
  static const Color warningLight = Color(0xFFFFFBEB); // Amber-50
  static const Color warningContainer = Color(0xFFFEF3C7); // Amber-100
  static const Color onWarning = Color(0xFFFFFFFF);

  static const Color error = Color(0xFFDC2626); // Red-600
  static const Color errorLight = Color(0xFFFEF2F2); // Red-50
  static const Color errorContainer = Color(0xFFFEE2E2); // Red-100
  static const Color onError = Color(0xFFFFFFFF);

  static const Color info = Color(0xFF0284C7); // Sky-600
  static const Color infoLight = Color(0xFFF0F9FF); // Sky-50
  static const Color infoContainer = Color(0xFFE0F2FE); // Sky-100
  static const Color onInfo = Color(0xFFFFFFFF);

  // === Sidebar Theme ===
  static const Color sidebarBg = Color(0xFF0F172A); // Slate-900
  static const Color sidebarItemActive = Color(0xFF2563EB); // Blue-600
  static const Color sidebarItemActiveText = Color(0xFFFFFFFF);
  static const Color sidebarItemText = Color(0xFF94A3B8); // Slate-400
  static const Color sidebarItemHover = Color(0xFF1E293B); // Slate-800
  static const Color sidebarDivider = Color(0xFF1E293B); // Slate-800

  // === Badges & Chips ===
  static const Color badgeBg = Color(0xFFF1F5F9);
  static const Color badgeText = Color(0xFF475569);

  // === Lead Status Colors ===
  static const Color statusNew = Color(0xFF7C3AED);
  static const Color statusNewBg = Color(0xFFF5F3FF);
  static const Color statusContacted = Color(0xFF0284C7);
  static const Color statusContactedBg = Color(0xFFE0F2FE);
  static const Color statusFollowUp = Color(0xFFD97706);
  static const Color statusFollowUpBg = Color(0xFFFEF3C7);
  static const Color statusMeeting = Color(0xFF6D28D9);
  static const Color statusMeetingBg = Color(0xFFEDE9FE);
  static const Color statusProposal = Color(0xFF0369A1);
  static const Color statusProposalBg = Color(0xFFE0F2FE);
  static const Color statusNegotiation = Color(0xFFB45309);
  static const Color statusNegotiationBg = Color(0xFFFEF9C3);
  static const Color statusWon = Color(0xFF16A34A);
  static const Color statusWonBg = Color(0xFFDCFCE7);
  static const Color statusLost = Color(0xFFDC2626);
  static const Color statusLostBg = Color(0xFFFEE2E2);

  // === Priority Colors ===
  static const Color priorityLow = Color(0xFF16A34A);
  static const Color priorityLowBg = Color(0xFFDCFCE7);
  static const Color priorityMedium = Color(0xFFD97706);
  static const Color priorityMediumBg = Color(0xFFFEF3C7);
  static const Color priorityHigh = Color(0xFFEA580C);
  static const Color priorityHighBg = Color(0xFFFFF7ED);
  static const Color priorityUrgent = Color(0xFFDC2626);
  static const Color priorityUrgentBg = Color(0xFFFEE2E2);

  // === Semantic Aliases ===
  static const Color primaryBlue = primary;
  static const Color darkSurface = surfaceDark;
  static const Color lightSurface = surface;
  static const Color darkSurfaceElevated = surfaceVariantDark;
  static const Color lightSurfaceElevated = surfaceVariant;
  static const Color cardSurface = surfaceVariant;
  static const Color cardSurfaceDark = surfaceVariantDark;
  static const Color darkBorder = surfaceBorderDark;
  static const Color lightBorder = surfaceBorder;
  static const Color border = surfaceBorder;
  static const Color borderDark = surfaceBorderDark;
  static const Color darkBackground = backgroundDark;
  static const Color lightBackground = background;
  static const Color darkTextPrimary = onSurfaceDark;
  static const Color lightTextPrimary = onSurface;
  static const Color darkTextSecondary = onSurfaceVariantDark;
  static const Color lightTextSecondary = onSurfaceVariant;
  static const Color darkTextTertiary = textMuted;
  static const Color lightTextTertiary = textMuted;
  static const Color accentTeal = Color(0xFF0D9488);
  static const Color accentPurple = Color(0xFF7C3AED);
  static const Color grey500 = Color(0xFF6B7280);

  // === Warning (for action buttons) ===
  static const Color warningDark = Color(0xFFB45309); // Amber-700

  // === Utility ===
  /// Transparent overlay for hover states
  static Color hoverOverlay(Brightness brightness) => brightness == Brightness.dark
      ? const Color(0x0AFFFFFF)
      : const Color(0x0A000000);

  static Color pressedOverlay(Brightness brightness) => brightness == Brightness.dark
      ? const Color(0x1AFFFFFF)
      : const Color(0x1A000000);
}

