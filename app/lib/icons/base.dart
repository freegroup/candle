import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:simple_shadow/simple_shadow.dart';

abstract class BaseSvgIcon extends StatelessWidget {
  final double? height;
  final double? width;
  final Color? color;
  final bool shadow;
  final int rotationDegrees; // The rotation angle in degrees

  const BaseSvgIcon({
    super.key,
    this.height,
    this.width,
    this.color,
    this.shadow = false,
    this.rotationDegrees = 0,
  });

  // Abstract method to get the asset path
  String get assetPath;

  @override
  Widget build(BuildContext context) {
    Color defaultColor =
        Theme.of(context).elevatedButtonTheme.style?.foregroundColor?.resolve({}) ?? Colors.black;

    double rotationRadians = rotationDegrees * (3.1415926535897932 / 180.0);

    if (!shadow) {
      return Transform.rotate(
        angle: rotationRadians,
        child: SvgPicture.asset(
          assetPath,
          colorFilter: ColorFilter.mode(color ?? defaultColor, BlendMode.srcIn),
          height: height ?? 24.0,
          width: width ?? 24.0,
        ),
      );
    }
    return SimpleShadow(
      opacity: 0.8, // Default: 0.5
      color: Colors.black, // Default: Black
      offset: const Offset(10, 20), // Default: Offset(2, 2)
      sigma: 3, // blur

      child: Transform.rotate(
        angle: rotationRadians,
        child: SvgPicture.asset(
          assetPath,
          colorFilter: ColorFilter.mode(color ?? defaultColor, BlendMode.srcIn),
          height: height ?? 24.0,
          width: width ?? 24.0,
        ),
      ),
    );
  }
}
