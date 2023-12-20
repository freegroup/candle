import 'package:candle/models/location_address.dart';
import 'package:candle/services/location.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LocationAddressTile extends StatefulWidget {
  const LocationAddressTile({super.key});

  @override
  State<LocationAddressTile> createState() => _LocationAddressTileState();
}

class _LocationAddressTileState extends State<LocationAddressTile> {
  String lat = "loading...", lon = "loading...";
  String street = "loading.....";
  String city = "loading.....";
  String number = "";
  bool _isVisible = true;
  DateTime? _lastUpdateOfAddress;

  @override
  void initState() {
    super.initState();
    _getLocation();
    LocationService.instance.updates.handleError((dynamic err) {
      print(err);
    }).listen((currentLocation) {
      if (_shouldUpdateLocationAddress()) {
        _getLocation();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const Key("xkJwBrIlXNYMmvdg0/wgxLJrmX1uOx6IYZIoVfc2"),
      onVisibilityChanged: (VisibilityInfo info) {
        _isVisible = info.visibleFraction > 0;
      },
      child: Semantics(
        label: AppLocalizations.of(context)!.home_address_t(street, number, city),
        child: ExcludeSemantics(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.05),
              border: Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 1.0), // Use primary color for border
              borderRadius: BorderRadius.circular(8.0), // Adjust radius for roundness
            ),
            constraints: const BoxConstraints(minHeight: 150.0), // Minimum height for the container
            child: Row(
              children: [
                Icon(
                  Icons.location_pin,
                  size: 90.0,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context)!.home_street(street, number),
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center),
                        Text(city,
                            style: Theme.of(context).textTheme.titleLarge,
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _shouldUpdateLocationAddress() {
    if (!_isVisible) return false;

    final now = DateTime.now();
    if (_lastUpdateOfAddress == null ||
        now.difference(_lastUpdateOfAddress!) > const Duration(minutes: 1)) {
      _lastUpdateOfAddress = now;
      return true;
    }
    return false;
  }

  void _getLocation() async {
    print("fetch Location");
    LocationData? data = await LocationService.instance.location;
    if (data != null) {
      print("Fetch Address...");
      final add = await getLocationAddress(lat: data.latitude!, lon: data.longitude!);
      if (add != null && mounted) {
        setState(() {
          number = add.number;
          street = add.street;
          city = add.city;
        });
      }
    }
  }

  Future<LocationAddress?> getLocationAddress({required double lat, required double lon}) async {
    try {
      String url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon';

      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        Map<String, dynamic> addressInfo = json.decode(response.body)['address'] ?? {};

        print(addressInfo);
        return LocationAddress(
          street: addressInfo['road'] ?? '',
          number: addressInfo['house_number'] ?? '',
          zip: addressInfo['postcode'] ?? '',
          city: addressInfo['city'] ?? addressInfo['town'] ?? addressInfo['municipality'] ?? '',
          country: addressInfo['country'] ?? '',
        );
      }
    } on Exception catch (error) {
      print(error);
    }
    return null;
  }
}
