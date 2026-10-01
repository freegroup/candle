import 'package:candle/ui/core/icons/base.dart';

class DirectionBaseIcon extends BaseSvgIcon {
  const DirectionBaseIcon({
    super.key,
    super.height,
    super.width,
    super.color,
    super.shadow,
    super.rotationDegrees,
  });

  @override
  String get assetPath =>
      'assets/images/direction_base.svg'; // Specify the asset path for the compass icon
}
