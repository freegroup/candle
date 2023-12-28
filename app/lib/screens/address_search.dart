import 'dart:async';
import 'package:candle/models/location_address.dart';
import 'package:candle/services/geocoding.dart';
import 'package:candle/services/place_api.dart';
import 'package:candle/widgets/accessible_text_input.dart';
import 'package:candle/widgets/appbar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

//Model classes that will be used for auto complete

class AddressSearchScreen extends StatefulWidget {
  final StreamSink<LocationAddress?> sink;
  final String? addressFragment;

  const AddressSearchScreen({super.key, required this.sink, this.addressFragment = ""});

  @override
  State<AddressSearchScreen> createState() => _ScreenState();
}

class _ScreenState extends State<AddressSearchScreen> {
  final _controller = TextEditingController();
  final provider = PlaceApiProvider(const Uuid().v4());
  List<LocationAddress> suggestion = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onSearchChanged);
    _controller.text = widget.addressFragment ?? "";
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (mounted) {
        if (_controller.text.length > 1) {
          var geo = Provider.of<GeoServiceProvider>(context, listen: false).service;
          Locale locale = Localizations.localeOf(context);
          suggestion = await geo.searchNearbyAddress(
            addressFragment: _controller.text,
            locale: locale,
          );
          if (mounted) {
            setState(() {});
          }
        } else {
          setState(() {
            suggestion.clear();
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onSearchChanged);
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: CandleAppBar(
        title: Text(AppLocalizations.of(context)!.address_search_dialog),
        talkback: AppLocalizations.of(context)!.address_search_dialog_t,
      ),
      body: Column(
        children: [
          AccessibleTextInput(
            controller: _controller,
            autofocus: true,
          ),
          const SizedBox(height: 18),
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
                        (suggestion[index]).formattedAddress,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: theme.primaryColor,
                          fontWeight: FontWeight.w500,
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
                  final placeDetail = suggestion[index];
                  widget.sink.add(placeDetail);
                  onBackPressed(context);
                },
              ),
              itemCount: suggestion.length,
            ),
          )
        ],
      ),
    );
  }
}

onBackPressed(BuildContext context) {
  print("BACK BACK BACK BACK BACK BACK BACK");
  Navigator.of(context).pop();
}
