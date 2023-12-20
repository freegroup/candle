import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CompassSvgIcon extends StatelessWidget {
  final double? height;
  final double? width;
  final Color? color;

  const CompassSvgIcon({super.key, this.height, this.width, this.color});

  @override
  Widget build(BuildContext context) {
    Color defaultColor =
        Theme.of(context).elevatedButtonTheme.style?.foregroundColor?.resolve({}) ?? Colors.black;

    return SvgPicture.asset(
      'assets/images/compass.svg', // Path to your SVG file
      colorFilter: ColorFilter.mode(color ?? defaultColor, BlendMode.srcIn),
      height: height ?? 24.0, // Set the height or width as needed
      width: width ?? 24.0,
    );
  }
}
