/// A tip about using Candle, in the language of the app.
class Tip {
  const Tip({required this.id, required this.title, required this.text, required this.read});

  /// Stable key, also for the read state.
  final String id;

  /// What the tip is about, e.g. "What are location notes?".
  final String title;

  /// The how and why; paragraphs are separated by an empty line.
  final String text;

  /// Whether the user has opened the tip.
  final bool read;

  /// [text] split into its paragraphs.
  List<String> get paragraphs =>
      text.split('\n\n').map((paragraph) => paragraph.trim()).where((paragraph) => paragraph.isNotEmpty).toList();
}
