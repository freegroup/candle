import 'dart:async';

import 'package:candle/services/geocoding.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddressSearchScreen extends StatefulWidget {
  const AddressSearchScreen({super.key});

  @override
  State<AddressSearchScreen> createState() => _ScreenState();
}

class _ScreenState extends State<AddressSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<AddressSearchResult> _searchResults = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();

    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.isNotEmpty) {
        print(".................=====================================");
        _performSearch(_searchController.text);
      } else {
        setState(() => _searchResults = []);
      }
    });
  }

  void _performSearch(String query) async {
    var geo = Provider.of<GeoServiceProvider>(context, listen: false).service;
    Locale locale = Localizations.localeOf(context);
    var results = await geo.searchNearbyAddress(addressFragment: query, locale: locale);
    if (mounted) {
      setState(() => _searchResults = results);
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Address Search')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomRight,
            end: Alignment.centerLeft,
            colors: [Colors.black, Color.fromARGB(255, 35, 34, 37)],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(hintText: 'Search address...'),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      _searchResults[index].formattedAddress,
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontSize: theme.textTheme.headlineSmall?.fontSize,
                      ),
                    ),
                    onTap: () {
                      // Handle selection
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
