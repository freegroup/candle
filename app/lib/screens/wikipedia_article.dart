import 'package:candle/models/article_summary.dart';
import 'package:candle/widgets/background.dart';
import 'package:flutter/material.dart';

class ArticleSummaryScreen extends StatelessWidget {
  final ArticleSummary summary;

  const ArticleSummaryScreen({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

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
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  border: Border.all(width: 1.0),
                ),
                child: Text(
                  summary.title ?? "",
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.left,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      summary.extract ?? "",
                      style: theme.textTheme.headlineMedium,
                    ),
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
