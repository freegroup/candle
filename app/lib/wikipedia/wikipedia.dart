import 'dart:convert';

import 'package:candle/wikipedia/model/response.dart';
import 'package:candle/wikipedia/model/summary.dart';
import 'package:http/http.dart' as http;

///This is the base URL[_baseUrl] for the Wikipedia API.
String _baseUrl = "https://en.wikipedia.org/w/api.php";

class Wikipedia {
  /// The searchQuery is for searching any type for query.
  /// You can search anything from wikipedia by using [searchQuery].
  /// You can also set limit for this results. By default the limit is set to 1.
  Future<Response?> searchQuery({required String searchQuery, int limit = 1}) async {
    try {
      final _responseData = await http.get(Uri.parse(
          "$_baseUrl?action=query&format=json&list=search&srlimit=$limit&srsearch=$searchQuery&origin=*"));
      return Response.fromJson(json.decode(_responseData.body));
    } catch (e) {
      return null;
    }
  }

  /// The searchSummaryWithPageId is for searching page with the help for page id.
  /// You can get page data by providing the page id. Page Id is required.
  Future<SummaryModel?> searchSummaryWithPageId({required int pageId}) async {
    try {
      final _responseData = await http.get(Uri.parse(
          "$_baseUrl?action=query&format=json&pageids=$pageId&prop=extracts|description&origin=*"));
      return SummaryModel.fromJson(json.decode(_responseData.body)["query"]["pages"]["$pageId"]);
    } catch (e) {
      print(e);
      return null;
    }
  }
}
