import 'package:candle/domain/models/location_address.dart';
import 'package:candle/l10n/app_localizations.dart';
import 'package:candle/ui/locations/view_models/address_search_viewmodel.dart';
import 'package:candle/ui/core/utils/semantic.dart';
import 'package:candle/ui/core/widgets/accessible_text_input.dart';
import 'package:candle/ui/core/widgets/appbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Address search with its own view model; pops with the chosen [LocationAddress].
Widget buildAddressSearchScreen({String query = ''}) => ChangeNotifierProvider(
      create: (context) => AddressSearchViewModel(
        geocodingRepository: context.read(),
        languageCode: Localizations.localeOf(context).languageCode,
      ),
      builder: (context, _) => AddressSearchScreen(viewModel: context.read(), query: query),
    );

class AddressSearchScreen extends StatefulWidget {
  const AddressSearchScreen({super.key, required this.viewModel, this.query = ''});

  final AddressSearchViewModel viewModel;
  final String query;

  @override
  State<AddressSearchScreen> createState() => _AddressSearchScreenState();
}

class _AddressSearchScreenState extends State<AddressSearchScreen> with SemanticAnnouncer {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.query;
    _controller.addListener(() => widget.viewModel.search(_controller.text));
    widget.viewModel.search(widget.query);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      announceOnShow(AppLocalizations.of(context)!.screen_header_address_search_t);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CandleAppBar(
        title: Text(l10n.screen_header_address_search),
        talkback: l10n.screen_header_address_search_t,
      ),
      body: Column(
        children: [
          AccessibleTextInput(
            controller: _controller,
            autofocus: true,
            talkbackInput: l10n.input_address_search_t,
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Semantics(
              header: true,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.address_search_list, style: theme.textTheme.headlineSmall),
              ),
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: widget.viewModel,
              builder: (context, _) {
                final results = widget.viewModel.results;
                return ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) => ListTile(
                    leading: Icon(Icons.place_rounded, color: theme.primaryColor, size: 32),
                    title: Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: Text(results[index].formattedAddress, style: theme.textTheme.bodyLarge),
                    ),
                    onTap: () => Navigator.of(context).pop<LocationAddress>(results[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
