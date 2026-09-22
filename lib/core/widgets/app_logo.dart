import 'package:flutter/material.dart';
import '../constants/app_assets.dart';
import '../constants/app_logo_data.dart';

enum LogoVariant {
  /// Just the "H" monogram mark
  iconOnly,

  /// Full horizontal logo (monogram + "HYTIDE" text)
  horizontal,

  /// Original square badge
  original,
}

class AppLogo extends StatelessWidget {
  final LogoVariant variant;
  final double? size;
  final double? width;
  final double? height;
  final bool transparent;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const AppLogo({
    super.key,
    this.variant = LogoVariant.iconOnly,
    this.size,
    this.width,
    this.height,
    this.transparent = true,
    this.fit = BoxFit.contain,
    this.borderRadius,
  });

  const AppLogo.icon({
    super.key,
    this.size = 36,
    this.transparent = true,
    this.borderRadius,
  })  : variant = LogoVariant.iconOnly,
        width = size,
        height = size,
        fit = BoxFit.contain;

  const AppLogo.horizontal({
    super.key,
    this.width,
    this.height = 36,
    this.transparent = true,
    this.fit = BoxFit.contain,
    this.borderRadius,
  })  : variant = LogoVariant.horizontal,
        size = null;

  const AppLogo.original({
    super.key,
    this.size = 120,
    this.borderRadius,
  })  : variant = LogoVariant.original,
        width = size,
        height = size,
        transparent = false,
        fit = BoxFit.contain;

  @override
  Widget build(BuildContext context) {
    Widget image;

    switch (variant) {
      case LogoVariant.iconOnly:
        image = Image.memory(
          AppLogoData.iconBytes,
          width: width ?? size,
          height: height ?? size,
          fit: fit,
        );
        break;
      case LogoVariant.horizontal:
        image = Image.memory(
          AppLogoData.logoBytes,
          width: width ?? size,
          height: height ?? size,
          fit: fit,
        );
        break;
      case LogoVariant.original:
        image = Image.asset(
          AppAssets.logoOriginal,
          width: width ?? size,
          height: height ?? size,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => Image.memory(
            AppLogoData.logoBytes,
            width: width ?? size,
            height: height ?? size,
            fit: fit,
          ),
        );
        break;
    }

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }
}
