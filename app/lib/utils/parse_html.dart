import 'package:html/parser.dart';

/// The parserHtml function is for parsing html into plain string.
class Html {
  static String toPlainText(String input) {
    final document = parse(input);
    final String parsedString = parse(document.body!.text).documentElement!.text;
    return parsedString;
  }
}
