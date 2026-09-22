// lib/core/theme/app_spacing.dart
import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  // === Base scale ===
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;
  static const double s40 = 40.0;
  static const double s48 = 48.0;

  // === Scale Aliases (double) ===
  static const double xs = s4;
  static const double sm = s8;
  static const double md = s16;
  static const double lg = s24;
  static const double xl = s32;
  static const double xxl = s48;

  // === Padding insets ===
  static const EdgeInsets p4 = EdgeInsets.all(s4);
  static const EdgeInsets p8 = EdgeInsets.all(s8);
  static const EdgeInsets p12 = EdgeInsets.all(s12);
  static const EdgeInsets p16 = EdgeInsets.all(s16);
  static const EdgeInsets p20 = EdgeInsets.all(s20);
  static const EdgeInsets p24 = EdgeInsets.all(s24);
  static const EdgeInsets p32 = EdgeInsets.all(s32);

  // === Horizontal padding ===
  static const EdgeInsets px8 = EdgeInsets.symmetric(horizontal: s8);
  static const EdgeInsets px12 = EdgeInsets.symmetric(horizontal: s12);
  static const EdgeInsets px16 = EdgeInsets.symmetric(horizontal: s16);
  static const EdgeInsets px20 = EdgeInsets.symmetric(horizontal: s20);
  static const EdgeInsets px24 = EdgeInsets.symmetric(horizontal: s24);
  static const EdgeInsets px32 = EdgeInsets.symmetric(horizontal: s32);

  // === Vertical padding ===
  static const EdgeInsets py4 = EdgeInsets.symmetric(vertical: s4);
  static const EdgeInsets py8 = EdgeInsets.symmetric(vertical: s8);
  static const EdgeInsets py12 = EdgeInsets.symmetric(vertical: s12);
  static const EdgeInsets py16 = EdgeInsets.symmetric(vertical: s16);
  static const EdgeInsets py20 = EdgeInsets.symmetric(vertical: s20);
  static const EdgeInsets py24 = EdgeInsets.symmetric(vertical: s24);

  // === Compound padding ===
  static const EdgeInsets cardPadding = EdgeInsets.all(s20);
  static const EdgeInsets cardPaddingMobile = EdgeInsets.all(s16);
  static const EdgeInsets pagePadding = EdgeInsets.all(s24);
  static const EdgeInsets pagePaddingMobile = EdgeInsets.all(s16);

  // === SizedBox Gaps (Horizontal) ===
  static const Widget gapW4 = SizedBox(width: s4);
  static const Widget gapW8 = SizedBox(width: s8);
  static const Widget gapW12 = SizedBox(width: s12);
  static const Widget gapW16 = SizedBox(width: s16);
  static const Widget gapW20 = SizedBox(width: s20);
  static const Widget gapW24 = SizedBox(width: s24);
  static const Widget gapW32 = SizedBox(width: s32);

  // === SizedBox Gaps (Vertical) ===
  static const Widget gapH4 = SizedBox(height: s4);
  static const Widget gapH8 = SizedBox(height: s8);
  static const Widget gapH12 = SizedBox(height: s12);
  static const Widget gapH16 = SizedBox(height: s16);
  static const Widget gapH20 = SizedBox(height: s20);
  static const Widget gapH24 = SizedBox(height: s24);
  static const Widget gapH32 = SizedBox(height: s32);
  static const Widget gapH40 = SizedBox(height: s40);
  static const Widget gapH48 = SizedBox(height: s48);
}
