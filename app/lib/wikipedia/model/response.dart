import 'package:candle/wikipedia/model/query.dart';

class Response {
  QueryModel? query;

  Response({this.query});

  Response.fromJson(Map<String, dynamic> json) {
    query = json['query'] != null ? QueryModel.fromJson(json['query']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (query != null) {
      data['query'] = query!.toJson();
    }
    return data;
  }
}
