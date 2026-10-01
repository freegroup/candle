import 'package:candle/domain/models/article_summary.dart';
import 'package:candle/ui/core/widgets/background.dart';
import 'package:flutter/material.dart';

/// Title and introduction of a Wikipedia article in large type; a tap closes it.
class ArticleScreen extends StatelessWidget {
  const ArticleScreen({super.key, required this.summary});

  final ArticleSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: SafeArea(
        child: BackgroundWidget(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: theme.cardColor, border: Border.all(width: 1.0)),
                child: Semantics(
                  header: true,
                  child: Text(summary.title, style: theme.textTheme.headlineMedium),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(summary.extract, style: theme.textTheme.headlineMedium),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
