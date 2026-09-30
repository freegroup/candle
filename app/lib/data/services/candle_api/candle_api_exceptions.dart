/// The Candle server (or the lookup of its address) cannot be reached:
/// the app works offline.
class ServerUnavailableException implements Exception {
  const ServerUnavailableException(this.message);

  final String message;

  @override
  String toString() => 'ServerUnavailableException: $message';
}

/// The server rejected the token or device proof (HTTP 401).
class UnauthorizedException implements Exception {
  const UnauthorizedException(this.message);

  final String message;

  @override
  String toString() => 'UnauthorizedException: $message';
}

/// Any other error answer of the server.
class CandleApiException implements Exception {
  const CandleApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'CandleApiException($statusCode): $message';
}
