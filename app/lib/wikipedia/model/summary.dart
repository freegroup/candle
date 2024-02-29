import 'package:candle/utils/parse_html.dart';

class SummaryModel {
  int? pageid;

  int? ns;
  String? title;
  String? extract;
  String? description;
  String? descriptionsource;

  SummaryModel({
    this.pageid,
    this.ns,
    this.title,
    this.extract,
    this.description,
    this.descriptionsource,
  });

  SummaryModel.fromJson(Map<String, dynamic> json) {
    pageid = json['pageid'];
    ns = json['ns'];
    title = json['title'];
    extract = Html.toPlainText(json['extract']);
    description = Html.toPlainText(json['description']);
    descriptionsource = json['descriptionsource'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['pageid'] = pageid;
    data['ns'] = ns;
    data['title'] = title;
    data['extract'] = extract;
    data['description'] = description;
    data['descriptionsource'] = descriptionsource;
    return data;
  }
}
