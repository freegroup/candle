import 'package:flutter/material.dart';

class SemanticHeader extends StatelessWidget {
  final String title;
  final String talkback;

  const SemanticHeader({
    super.key,
    required this.title,
    required this.talkback,
  });

  @override
  Widget build(BuildContext context) {
    var mediaQueryData = MediaQuery.of(context);
    bool isScreenReaderEnabled = mediaQueryData.accessibleNavigation;

    return isScreenReaderEnabled
        ? Semantics(
            label: talkback,
            child: ExcludeSemantics(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.0),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
            ),
          )
        : SizedBox.shrink(); // Returns an empty widget if screen reader is not enabled
  }
}
