import 'dart:convert';
import 'package:candle/auth/secrets.dart';
import 'package:http/http.dart' as http;

class Suggestion {
  final String placeId;
  final String description;
  final String title;
  Suggestion(this.placeId, this.description, this.title);
}

class PlaceDetail {
  String? address;
  double? latitude;
  double? longitude;
  String? name;

  PlaceDetail({
    this.address,
    this.latitude,
    this.longitude,
    this.name,
  });
}

// We will use this util class to fetch the auto complete result and get the details of the place.
class PlaceApiProvider {
  PlaceApiProvider(this.sessionToken);

  final String sessionToken;
  final apiKey = GOOGLE_API_KEY;

  http.Request createGetRequest(String url) => http.Request('GET', Uri.parse(url));

  Future<List<Suggestion>> fetchSuggestions(String input) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&components=country:sg&key=$apiKey&sessiontoken=$sessionToken';
    var request = createGetRequest(url);
    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      final data = await response.stream.bytesToString();
      final result = json.decode(data);

      print(result);

      if (result['status'] == 'OK') {
        return result['predictions']
            .map<Suggestion>((p) => Suggestion(
                p['place_id'], p['description'], p['structured_formatting']['main_text']))
            .toList();
      }
      if (result['status'] == 'ZERO_RESULTS') {
        return [];
      }
      throw Exception(result['error_message']);
    } else {
      throw Exception('Failed to fetch suggestion');
    }
  }

  Future<PlaceDetail> getPlaceDetailFromId(String placeId) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=formatted_address,name,geometry/location&key=$apiKey&sessiontoken=$sessionToken';
    var request = createGetRequest(url);
    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      final data = await response.stream.bytesToString();
      final result = json.decode(data);
      print(result);

      if (result['status'] == 'OK') {
        // build result
        final place = PlaceDetail();
        place.address = result['result']['formatted_address'];
        place.latitude = result['result']['geometry']['location']['lat'];
        place.longitude = result['result']['geometry']['location']['lng'];
        place.name = result['result']['geometry']['name'];
        return place;
      }
      throw Exception(result['error_message']);
    } else {
      throw Exception('Failed to fetch suggestion');
    }
  }
}
