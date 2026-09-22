// lib/core/theme/app_radius.dart
import 'package:flutter/material.dart';

class AppRadius {
  AppRadius._();

  // === Base scale ===
  static const double r4 = 4.0;
  static const double r6 = 6.0;
  static const double r8 = 8.0;
  static const double r10 = 10.0;
  static const double r12 = 12.0;
  static const double r16 = 16.0;
  static const double r20 = 20.0;
  static const double r24 = 24.0;
  static const double rFull = 9999.0;

  // === Radius objects ===
  static const Radius radius4 = Radius.circular(r4);
  static const Radius radius6 = Radius.circular(r6);
  static const Radius radius8 = Radius.circular(r8);
  static const Radius radius10 = Radius.circular(r10);
  static const Radius radius12 = Radius.circular(r12);
  static const Radius radius16 = Radius.circular(r16);
  static const Radius radius24 = Radius.circular(r24);
  static const Radius radiusFull = Radius.circular(rFull);

  // === BorderRadius objects ===
  static const BorderRadius br4 = BorderRadius.all(radius4);
  static const BorderRadius br6 = BorderRadius.all(radius6);
  static const BorderRadius br8 = BorderRadius.all(radius8);
  static const BorderRadius br10 = BorderRadius.all(radius10);
  static const BorderRadius br12 = BorderRadius.all(radius12);
  static const BorderRadius br16 = BorderRadius.all(radius16);
  static const BorderRadius br24 = BorderRadius.all(radius24);
  static const BorderRadius brFull = BorderRadius.all(radiusFull);

  // === Component Aliases ===
  static const BorderRadius card = br12;
  static const BorderRadius button = br8;
  static const BorderRadius input = br8;
  static const BorderRadius badge = br6;
  static const BorderRadius modal = br16;
  static const BorderRadius toast = br10;

  // === Scale Aliases (double) ===
  static const double xs = r4;
  static const double sm = r8;
  static const double md = r12;
  static const double lg = r16;
  static const double xl = r24;
  static const double full = rFull;
}
