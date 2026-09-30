import 'package:candle/guidance/simple.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final guidance = SimpleGuidance();

  test('isAligned tolerates ±8°', () {
    expect(guidance.isAligned(100, 100), isTrue);
    expect(guidance.isAligned(108, 100), isTrue);
    expect(guidance.isAligned(92, 100), isTrue);
    expect(guidance.isAligned(109, 100), isFalse);
  });

  test('isAligned wraps around north', () {
    expect(guidance.isAligned(356, 2), isTrue);
    expect(guidance.isAligned(2, 356), isTrue);
    expect(guidance.isAligned(350, 10), isFalse);
  });
}
