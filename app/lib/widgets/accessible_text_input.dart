import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AccessibleTextInput extends StatefulWidget {
  final TextEditingController controller;
  final InputDecoration? decoration;
  final bool? autofocus;
  final String hintText;
  final Function(String)? onSubmitted;
  final String? talkbackInput; // Semantic label for the input field
  final String? talkbackIcon; // Semantic label for the icon

  const AccessibleTextInput({
    super.key,
    required this.controller,
    this.decoration,
    this.autofocus,
    this.hintText = '',
    this.onSubmitted,
    this.talkbackInput,
    this.talkbackIcon,
  });

  @override
  State<AccessibleTextInput> createState() => _InputState();
}

class _InputState extends State<AccessibleTextInput> {
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          print('onStatus: $val');
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            widget.controller.text = val.recognizedWords;
            if (val.finalResult && widget.onSubmitted != null) {
              widget.onSubmitted!(val.recognizedWords);
            }
          }),
        );
      }
    } else {
      _speech.stop();
      setState(() => _isListening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Semantics(
            label: widget.talkbackInput ?? 'Text input',
            child: ExcludeSemantics(
              child: TextField(
                controller: widget.controller,
                decoration: widget.decoration ?? InputDecoration(hintText: widget.hintText),
                autofocus: widget.autofocus ?? false,
                onSubmitted: widget.onSubmitted,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 0, // Ensures that IconButton takes minimum space
          child: Semantics(
            label: widget.talkbackIcon ?? 'Speech Input',
            child: Align(
              alignment: Alignment.center,
              child: ExcludeSemantics(
                child: IconButton(
                  color: theme.primaryColor,
                  iconSize: 48,
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                  onPressed: _listen,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }
}
