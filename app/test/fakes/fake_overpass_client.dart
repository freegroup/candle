import 'package:candle/data/services/overpass/overpass_client.dart';
import 'package:candle/data/services/overpass/overpass_element.dart';
import 'package:candle/utils/result.dart';
import 'package:http/testing.dart';

class FakeOverpassClient extends OverpassClient {
  FakeOverpassClient(this.result)
      : super(client: MockClient((_) => throw UnimplementedError()));

  Result<List<OverpassElement>> result;
  final queries = <String>[];

  @override
  Future<Result<List<OverpassElement>>> query(String overpassQl) async {
    queries.add(overpassQl);
    return result;
  }
}
