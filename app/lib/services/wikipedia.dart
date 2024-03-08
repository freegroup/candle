import 'dart:convert';
import 'dart:ui';

import 'package:candle/models/article_ref.dart';
import 'package:candle/models/article_summary.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// action=query&list=geosearch&gsradius=10000&gscoord=37.786971%7C-122.399677
class WikipediaService {
  /// The searchQuery is for searching any type for query.
  /// You can search anything from wikipedia by using [searchQuery].
  /// You can also set limit for this results. By default the limit is set to 1.
  static String _getBaseUrlForLocale(Locale locale) {
    // Default to English Wikipedia
    String baseUrl = "https://en.wikipedia.org/w/api.php";
    // If the user's locale is German, use the German Wikipedia
    if (locale.languageCode.toLowerCase() == "de") {
      baseUrl = "https://de.wikipedia.org/w/api.php";
    }
    return baseUrl;
  }

  static Future<List<ArticleRef>> search({
    required BuildContext context,
    required LatLng location,
    int limit = 40,
    int radius = 10000,
  }) async {
    try {
      // Get the current locale from the context
      Locale currentLocale = Localizations.localeOf(context);
      // Determine the base URL based on the user's language
      String _baseUrl = _getBaseUrlForLocale(currentLocale);

      final response = await http.get(Uri.parse(
          "$_baseUrl?action=query&uselang=de&list=geosearch&gsprop=type&format=json&gsradius=$radius&gscoord=${location.latitude}%7C${location.longitude}"));
      print(response.body);
      final jsonResult = json.decode(response.body);
      final articlesJson = jsonResult['query']['geosearch'] as List;
      List<ArticleRef> articles = articlesJson.map((articleJson) {
        return ArticleRef.fromJson(articleJson);
      }).toList();
      //print(articles);
      return articles;
    } catch (e) {
      print(e);
      return [];
    }
  }

  /// The searchSummaryWithPageId is for searching page with the help for page id.
  /// You can get page data by providing the page id. Page Id is required.
  static Future<ArticleSummary?> getSummary({
    required BuildContext context,
    required ArticleRef ref,
  }) async {
    try {
      // Get the current locale from the context
      Locale currentLocale = Localizations.localeOf(context);
      // Determine the base URL based on the user's language
      String _baseUrl = _getBaseUrlForLocale(currentLocale);

      final data = await http.get(Uri.parse(
          "$_baseUrl?action=query&format=json&pageids=${ref.pageid}&prop=extracts|description&origin=*"));
      return ArticleSummary.fromJson(json.decode(data.body)["query"]["pages"]["${ref.pageid}"]);
    } catch (e) {
      print(e);
      return null;
    }
  }
}
