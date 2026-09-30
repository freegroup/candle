import 'package:candle/data/services/attestation/attestation_service.dart';
import 'package:candle/utils/result.dart';

class FakeAttestationService implements AttestationService {
  /// Error returned instead of a proof, e.g. [InvalidKeyException].
  Exception? assertionError;
  Exception? attestError;
  int keys = 0;
  final List<String?> assertionKeyIds = [];

  @override
  Future<Result<DeviceProof>> attest(String challenge) async {
    if (attestError != null) return Result.error(attestError!);
    keys++;
    return Result.ok(DeviceProof('ios', {'keyId': 'key-$keys', 'attestation': 'att-$challenge'}));
  }

  @override
  Future<Result<DeviceProof>> assertion(String challenge, {String? keyId}) async {
    assertionKeyIds.add(keyId);
    if (assertionError != null) return Result.error(assertionError!);
    return Result.ok(DeviceProof('ios', {'assertion': 'sig-$challenge'}));
  }
}
