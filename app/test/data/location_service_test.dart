import 'dart:async';

import 'package:candle/data/services/location/location_service.dart';
import 'package:candle/utils/result.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

/// Records every platform stream the service opens.
class _Platform {
  final streams = <StreamController<LatLng>>[];
  int currentPositionCalls = 0;

  Stream<LatLng> source(Object _) {
    final controller = StreamController<LatLng>();
    streams.add(controller);
    return controller.stream;
  }

  Future<Result<LatLng>> current() async {
    currentPositionCalls++;
    return const Result.ok(LatLng(9, 9));
  }

  bool get running => streams.isNotEmpty && streams.last.hasListener;
}

void main() {
  late _Platform platform;
  late DateTime now;

  LocationService create() => LocationService(
        source: platform.source,
        currentPositionSource: platform.current,
        now: () => now,
      );

  setUp(() {
    platform = _Platform();
    now = DateTime(2026);
  });

  test('all screens share one platform stream', () {
    fakeAsync((async) {
      final service = create();
      final a = <LatLng>[], b = <LatLng>[];
      service.positions().listen(a.add);
      service.positions().listen(b.add);
      platform.streams.single.add(const LatLng(1, 1));
      async.flushMicrotasks();

      expect(platform.streams, hasLength(1));
      expect(a, [const LatLng(1, 1)]);
      expect(b, [const LatLng(1, 1)]);
    });
  });

  test('switching screens does not stop GPS; it stops a while after the last one left', () {
    fakeAsync((async) {
      final service = create();
      final first = service.positions().listen((_) {});
      async.flushMicrotasks();
      unawaited(first.cancel());
      async.elapse(const Duration(seconds: 5));
      expect(platform.running, isTrue);

      final second = service.positions().listen((_) {});
      async.flushMicrotasks();
      expect(platform.streams, hasLength(1), reason: 'the running stream is reused');

      unawaited(second.cancel());
      async.elapse(const Duration(seconds: 21));
      expect(platform.running, isFalse);
    });
  });

  test('a new screen gets the last position at once if it is fresh', () {
    fakeAsync((async) {
      final service = create();
      final first = service.positions().listen((_) {});
      platform.streams.single.add(const LatLng(1, 1));
      async.flushMicrotasks();
      unawaited(first.cancel());

      final received = <LatLng>[];
      service.positions().listen(received.add);
      async.flushMicrotasks();
      expect(received, [const LatLng(1, 1)]);

      now = now.add(const Duration(minutes: 1));
      final late = <LatLng>[];
      service.positions().listen(late.add);
      async.flushMicrotasks();
      expect(late, isEmpty, reason: 'an old position is not handed out');
    });
  });

  test('currentPosition answers from a fresh position without asking GPS', () async {
    final service = create();
    service.positions().listen((_) {});
    await pumpEventQueue();
    platform.streams.single.add(const LatLng(1, 1));
    await pumpEventQueue();

    expect((await service.currentPosition() as Ok<LatLng>).value, const LatLng(1, 1));
    expect(platform.currentPositionCalls, 0);

    now = now.add(const Duration(minutes: 1));
    expect((await service.currentPosition() as Ok<LatLng>).value, const LatLng(9, 9));
    expect(platform.currentPositionCalls, 1);
  });

  test('a recording switches the stream to the foreground service and back', () {
    fakeAsync((async) {
      final service = create();
      final screen = <LatLng>[];
      service.positions().listen(screen.add);
      async.flushMicrotasks();
      expect(platform.streams, hasLength(1));

      final recorded = <LatLng>[];
      final recording =
          service.backgroundPositions(title: 't', text: 'x').listen(recorded.add);
      async.flushMicrotasks();
      expect(platform.streams, hasLength(2), reason: 'restarted with the recording settings');
      expect(platform.streams.first.hasListener, isFalse);

      platform.streams.last.add(const LatLng(2, 2));
      async.flushMicrotasks();
      expect(recorded, [const LatLng(2, 2)]);
      expect(screen, [const LatLng(2, 2)], reason: 'screens keep receiving positions');

      unawaited(recording.cancel());
      async.flushMicrotasks();
      expect(platform.streams, hasLength(3), reason: 'back to the normal settings');
    });
  });
}
