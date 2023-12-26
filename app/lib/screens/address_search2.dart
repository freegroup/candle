import 'dart:async';
import 'package:candle/services/place_api.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

//Model classes that will be used for auto complete

class AddressSearchScreen2 extends StatefulWidget {
  final title;
  final StreamSink<PlaceDetail> sink;

  const AddressSearchScreen2({Key? key, required this.title, required this.sink}) : super(key: key);

  @override
  State<AddressSearchScreen2> createState() => _ScreenState();
}

class _ScreenState extends State<AddressSearchScreen2> {
  final _controller = TextEditingController();
  final sessionToken = Uuid().v4();
  final provider = PlaceApiProvider(Uuid().v4());
  List<Suggestion> suggestion = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() async {
      if (_controller.text.length > 1)
        suggestion = await provider.fetchSuggestions(_controller.text);
      else {
        suggestion.clear();
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: onBackPressed(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  iconSize: 32,
                  padding: EdgeInsets.only(left: 16, top: 8),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 16, top: 16, bottom: 4),
                  child: Text(
                    widget.title,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.only(left: 18, top: 8, right: 18),
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                textAlign: TextAlign.start,
                autocorrect: false,
                autofocus: true,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  icon: Container(
                    margin: EdgeInsets.only(left: 12),
                    width: 32,
                    child: Icon(
                      Icons.search_rounded,
                      color: Colors.black,
                      size: 32,
                    ),
                  ),
                  hintText: "Enter location",
                  border: InputBorder.none,
                ),
              ),
            ),
            SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemBuilder: (context, index) => ListTile(
                  title: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 4),
                        child: Text(
                          (suggestion[index]).title,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4, bottom: 8),
                        child: Text(
                          (suggestion[index]).description,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    ],
                  ),
                  leading: Container(
                    child: Icon(
                      Icons.place_rounded,
                      color: Colors.amberAccent,
                      size: 32,
                    ),
                  ),
                  onTap: () async {
                    final placeDetail =
                        await provider.getPlaceDetailFromId(suggestion[index].placeId);
                    widget.sink.add(placeDetail);
                    onBackPressed(context);
                  },
                ),
                itemCount: suggestion.length,
              ),
            )
          ],
        ),
      ),
    );
  }
}

onBackPressed(BuildContext context) => Navigator.of(context).pop();
