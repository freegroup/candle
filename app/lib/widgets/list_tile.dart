import 'package:flutter/material.dart';

class CandleListTile extends StatelessWidget {
  const CandleListTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 5, top: 1, right: 5),
        child: Container(
          decoration: BoxDecoration(
            // color: Colors.black,
            gradient: const LinearGradient(
              colors: [Color.fromRGBO(12, 12, 12, 1), Color.fromRGBO(3, 3, 3, 1)],
              stops: [0.25, 0.75],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor, // Adjust the color as needed
                width: 2.0, // Adjust the width as needed
              ),
            ),
          ),
          child: IntrinsicHeight(
            // Forces children to fill available vertical space
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch row children vertically
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.headlineSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium!.copyWith(
                            color: theme.primaryColor.withOpacity(0.5),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 18.0, top: 18),
                  child: Container(
                    width: 100,

                    //color: theme.cardColor,
                    decoration: BoxDecoration(
                      //color: Colors.black,
                      border: Border(
                        left: BorderSide(
                          color: theme.dividerColor, // Adjust the color as needed
                          width: 1.0, // Adjust the width as needed
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        trailing ?? "",
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
