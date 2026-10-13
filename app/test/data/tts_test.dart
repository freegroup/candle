import 'package:candle/data/services/tts/tts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const interruptChannel = MethodChannel('candle/accessibility');

  testWidgets('say hands the text to the screen reader', (tester) async {
    final announced = <String>[];
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<Object?>(
      SystemChannels.accessibility,
      (message) async {
        final map = message! as Map<Object?, Object?>;
        if (map['type'] == 'announce') {
          announced.add((map['data']! as Map<Object?, Object?>)['message']! as String);
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockDecodedMessageHandler<Object?>(SystemChannels.accessibility, null));

    await TTS.say('50 Meter, links');

    expect(announced, ['50 Meter, links']);
  });

  testWidgets('interrupt stops the screen reader', (tester) async {
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(interruptChannel, (call) async {
      calls.add(call.method);
      return null;
    });
    addTearDown(() =>
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(interruptChannel, null));

    await TTS.interrupt();

    expect(calls, ['interrupt']);
  });
}
