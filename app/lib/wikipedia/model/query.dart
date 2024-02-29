import 'package:candle/wikipedia/model/search.dart';

class QueryModel {
  List<SearchModel>? search;

  QueryModel({this.search});

  QueryModel.fromJson(Map<String, dynamic> json) {
    if (json['search'] != null) {
      search = <SearchModel>[];
      json['search'].forEach((v) {
        search!.add(SearchModel.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (search != null) {
      data['search'] = search!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
