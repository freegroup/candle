import 'package:candle/widgets/appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  void showDeleteConfirmation(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Favorit wurd gelöscht'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  int? selectedItemIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CandleAppBar(
          title: Text(AppLocalizations.of(context)!.favorite_mainmenu),
          talkback: AppLocalizations.of(context)!.favorite_mainmenu_t,
        ),
        body: Center(
          child: SlidableAutoCloseBehavior(
            closeWhenOpened: true,
            child: ListView.builder(
              itemCount: 100,
              itemBuilder: (context, index) {
                bool isSelected = selectedItemIndex == index;
                return Semantics(
                  customSemanticsActions: {
                    const CustomSemanticsAction(label: 'Edit'): () {
                      showDeleteConfirmation(context);
                    },
                    const CustomSemanticsAction(label: 'Delete'): () {
                      showDeleteConfirmation(context);
                    },
                  },
                  child: Slidable(
                    endActionPane: ActionPane(
                      // A motion is a widget used to control how the pane animates.
                      motion: const ScrollMotion(),

                      // All actions are defined in the children parameter.
                      children: [
                        // A SlidableAction can have an icon and/or a label.
                        SlidableAction(
                          onPressed: (context) {},
                          backgroundColor: Color(0xFFFE4A49),
                          foregroundColor: Colors.white,
                          icon: Icons.delete,
                          label: 'Delete',
                        ),
                        SlidableAction(
                          onPressed: (context) {},
                          backgroundColor: Color(0xFF21B7CA),
                          foregroundColor: Colors.white,
                          icon: Icons.share,
                          label: 'Share',
                        ),
                      ],
                    ),
                    child: ListTile(
                        title: Text(
                          'Item $index',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
                          ),
                        ),
                        tileColor:
                            isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
                        onTap: () {
                          setState(() {
                            selectedItemIndex = index;
                          });
                        }),
                  ),
                );
              },
            ),
          ),
        ));
  }
}
