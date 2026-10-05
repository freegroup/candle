import 'package:candle/data/services/accessibility/accessibility_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('candle/accessibility');
  late List<String> calls;

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return null;
    });
  });

  tearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null));

  test('interrupts the screen reader on Android', () async {
    await AccessibilityService(platform: TargetPlatform.android).interrupt();
    expect(calls, ['interrupt']);
  });

  test('does nothing on iOS', () async {
    await AccessibilityService(platform: TargetPlatform.iOS).interrupt();
    expect(calls, isEmpty);
  });

  test('a missing native side is no error', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await AccessibilityService(platform: TargetPlatform.android).interrupt();
  });
}
