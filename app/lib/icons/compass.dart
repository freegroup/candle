import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CompassSvgIcon extends StatelessWidget {
  final double? height;
  final double? width;
  final Color? color;
  final double rotationDegrees; // The rotation angle in degrees

  const CompassSvgIcon({
    super.key,
    this.height,
    this.width,
    this.color,
    this.rotationDegrees = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    Color defaultColor =
        Theme.of(context).elevatedButtonTheme.style?.foregroundColor?.resolve({}) ?? Colors.black;

    // Convert degrees to radians for the rotation
    double rotationRadians = rotationDegrees * (3.1415926535897932 / 180.0);

    return Transform.rotate(
      angle: rotationRadians,
      child: SvgPicture.asset(
        'assets/images/compass.svg', // Path to your SVG file
        colorFilter: ColorFilter.mode(color ?? defaultColor, BlendMode.srcIn),
        height: height ?? 24.0, // Set the height or width as needed
        width: width ?? 24.0,
      ),
    );
  }
}
