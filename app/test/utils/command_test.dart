import 'dart:async';

import 'package:candle/utils/command.dart';
import 'package:candle/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Command0 reports running, then the result', () async {
    final completer = Completer<Result<int>>();
    final command = Command0<int>(() => completer.future);

    final future = command.execute();
    expect(command.running, isTrue);

    completer.complete(const Result.ok(42));
    await future;
    expect(command.running, isFalse);
    expect(command.completed, isTrue);
    expect((command.result! as Ok<int>).value, 42);
  });

  test('Command0 ignores a second execute while running', () async {
    var calls = 0;
    final completer = Completer<Result<void>>();
    final command = Command0<void>(() {
      calls++;
      return completer.future;
    });

    final first = command.execute();
    unawaited(command.execute());
    completer.complete(const Result.ok(null));
    await first;
    expect(calls, 1);
  });

  test('Command1 passes its argument and exposes errors', () async {
    final command = Command1<void, String>((arg) async => Result.error(Exception(arg)));
    await command.execute('boom');
    expect(command.error, isTrue);
    expect((command.result! as Error<void>).error.toString(), contains('boom'));
  });
}
