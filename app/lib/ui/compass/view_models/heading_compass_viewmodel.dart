import 'package:candle/ui/compass/view_models/base_compass_viewmodel.dart';
import 'package:candle/utils/geo.dart';

/// The heading of the phone, snapped to the eight compass directions.
class HeadingCompassViewModel extends BaseCompassViewModel {
  HeadingCompassViewModel({required super.compassService, super.tiltWarningDelay});

  int? _snappedDirection;

  /// The compass direction the phone points to, null between two directions.
  int? get snappedDirection => _snappedDirection;

  @override
  void onHeadingChanged(int heading) => _snappedDirection = snapToDirection(heading);
}
