import 'package:candle/data/services/ors/ors_client.dart';
import 'package:candle/domain/models/route.dart';
import 'package:candle/utils/result.dart';
import 'package:latlong2/latlong.dart';

/// Walking routes between two positions.
// TODO(server): route through the Candle server, so the ORS key leaves the app.
class RoutingRepository {
  RoutingRepository({required this._ors});

  final OrsClient _ors;

  Future<Result<Route>> walkingRoute(LatLng start, LatLng end) => _ors.walkingRoute(start, end);
}
