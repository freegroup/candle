import 'package:candle/utils/parse_html.dart';

class SearchModel {
  int? ns;
  String? title;
  int? pageid;
  int? size;
  int? wordcount;
  String? snippet;
  String? timestamp;

  SearchModel({
    this.ns,
    this.title,
    this.pageid,
    this.size,
    this.wordcount,
    this.snippet,
    this.timestamp,
  });

  SearchModel.fromJson(Map<String, dynamic> json) {
    ns = json['ns'];
    title = json['title'];
    pageid = json['pageid'];
    size = json['size'];
    wordcount = json['wordcount'];
    snippet = Html.toPlainText(json['snippet']);
    timestamp = json['timestamp'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['ns'] = ns;
    data['title'] = title;
    data['pageid'] = pageid;
    data['size'] = size;
    data['wordcount'] = wordcount;
    data['snippet'] = snippet;
    data['timestamp'] = timestamp;
    return data;
  }
}
