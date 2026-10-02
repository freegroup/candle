import 'package:candle/ui/core/widgets/compass_rose.dart';
import 'package:flutter_test/flutter_test.dart';

Matcher near(Offset expected) => predicate<Offset>(
    (o) => (o - expected).distance < 0.001, 'near (${expected.dx}, ${expected.dy})');

void main() {
  const r = 10.0;

  test('facing north, N is at the top and E on the right', () {
    expect(compassLabelPosition(direction: 0, heading: 0, radius: r), near(const Offset(0, -r)));
    expect(compassLabelPosition(direction: 90, heading: 0, radius: r), near(const Offset(r, 0)));
  });

  test('facing east, E is at the top (ahead) and N on the left', () {
    expect(compassLabelPosition(direction: 90, heading: 90, radius: r), near(const Offset(0, -r)));
    expect(compassLabelPosition(direction: 0, heading: 90, radius: r), near(const Offset(-r, 0)));
  });

  test('facing south, N is at the bottom', () {
    expect(compassLabelPosition(direction: 0, heading: 180, radius: r), near(const Offset(0, r)));
  });
}
