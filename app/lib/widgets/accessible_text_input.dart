import 'package:candle/utils/featureflag.dart';
import 'package:candle/utils/global_logger.dart';
import 'package:candle/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AccessibleTextInput extends StatefulWidget {
  final TextEditingController controller;
  final InputDecoration? decoration;
  final bool mandatory;
  final bool hideMicrophone;
  final bool? autofocus;
  final String hintText;
  final int maxLines;
  final Function(String)? onSubmitted;
  final String? talkbackInput; // Semantic label for the input field
  final String? talkbackIcon; // Semantic label for the icon

  const AccessibleTextInput({
    super.key,
    required this.controller,
    this.decoration,
    this.autofocus,
    this.mandatory = false,
    this.hideMicrophone = false,
    this.maxLines = 1,
    this.hintText = '',
    this.onSubmitted,
    this.talkbackInput,
    this.talkbackIcon,
  });

  @override
  State<AccessibleTextInput> createState() => _InputState();
}

class _InputState extends State<AccessibleTextInput> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    checkMicrophoneAvailability();
    widget.controller.addListener(_onTextChanged);
  }

  void checkMicrophoneAvailability() async {
    if (AppFeatures.dictationInput.isNotEnabled) {
      return;
    }

    try {
      bool available = await _speech.initialize();
      if (available) {
        print('Microphone available: $available');
      } else {
        print("The user has denied the use of speech recognition.");
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void dispose() {
    _speech.stop();
    widget.controller.removeListener(_onTextChanged); // Remove listener
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _listen() async {
    // do not start listen if the feature is not enabled
    assert(AppFeatures.dictationInput.isEnabled);

    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (val) => log.e('onError: $val'),
      );
      if (available) {
        if (mounted) setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            widget.controller.text = val.recognizedWords;
            if (val.finalResult) {
              AppLocalizations l10n = AppLocalizations.of(context)!;
              showSnackbar(context, l10n.accessible_text_snackbar(val.recognizedWords));
              // Remove focus and hide keyboard
              FocusScope.of(context).unfocus();
              if (widget.onSubmitted != null) {
                widget.onSubmitted!(val.recognizedWords);
              }
            }
          }),
        );
      }
    } else {
      _speech.stop();
      if (mounted) setState(() => _isListening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label in der ersten Zeile
        _buildInputLabel(),
        // Textfeld und Icon in der zweiten Zeile
        (AppFeatures.dictationInput.isEnabled && widget.hideMicrophone == false)
            ? _buildDictationInputField()
            : _buildInputField(),
      ],
    );
  }

  Widget _buildInputField() {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);
    bool showError = widget.mandatory && widget.controller.text.isEmpty;

    return Semantics(
      label: widget.talkbackInput ?? l10n.accessible_text_input_t,
      child: TextField(
        controller: widget.controller,
        decoration: widget.decoration?.copyWith(
              errorText: showError ? l10n.label_common_required : null,
            ) ??
            InputDecoration(hintStyle: TextStyle(color: theme.primaryColor)),
        autofocus: widget.autofocus ?? false,
        onSubmitted: widget.onSubmitted,
        maxLines: widget.maxLines,
        keyboardType: widget.maxLines > 1 ? TextInputType.multiline : TextInputType.text,
      ),
    );
  }

  Widget _buildDictationInputField() {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);
    bool showError = widget.mandatory && widget.controller.text.isEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Semantics(
            label: widget.talkbackInput == null
                ? "${l10n.accessible_text_input_t} ${l10n.accessible_text_suffix_t}"
                : "${widget.talkbackInput} ${l10n.accessible_text_suffix_t}",
            child: ExcludeSemantics(
              child: TextField(
                controller: widget.controller,
                decoration: widget.decoration?.copyWith(
                      errorText: showError ? l10n.label_common_required : null,
                    ) ??
                    InputDecoration(
                      hintStyle: TextStyle(color: theme.primaryColor),
                    ),
                autofocus: widget.autofocus ?? false,
                onSubmitted: widget.onSubmitted,
                maxLines: widget.maxLines,
                keyboardType: widget.maxLines > 1 ? TextInputType.multiline : TextInputType.text,
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: Semantics(
            label: widget.talkbackIcon ?? 'Speech Input',
            child: ExcludeSemantics(
              child: IconButton(
                color: theme.primaryColor,
                icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                onPressed: _listen,
                padding: EdgeInsets.zero,
                iconSize: 48, // Icon-Größe
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputLabel() {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    ThemeData theme = Theme.of(context);
    return ExcludeSemantics(
      child: Text(
        widget.mandatory ? "${widget.hintText} *" : widget.hintText,
        style: theme.textTheme.labelMedium,
      ),
    );
  }
}
