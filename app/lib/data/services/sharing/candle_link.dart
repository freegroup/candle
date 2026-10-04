import 'dart:convert';

/// The host and path of the shareable https links that open Candle and import a
/// point. The association files live under this host's `.well-known/`.
const candleLinkHost = 'freegroup.de';
const candleLinkPathPrefix = '/candle/share';

/// Builds the shareable link for [data], the same JSON map the `.candle` files
/// use (`{'locations': [...]}` or `{'voicepins': [...]}`), as a base64url payload.
Uri buildShareUri(Map<String, Object> data) {
  final payload = base64Url.encode(utf8.encode(jsonEncode(data)));
  return Uri.https(candleLinkHost, '$candleLinkPathPrefix/', {'d': payload});
}

/// Decodes the `d` payload of a Candle share link back to its JSON string, or
/// null if [uri] is not a Candle share link or the payload is broken.
String? decodeShareLink(Uri uri) {
  if (uri.host != candleLinkHost || !uri.path.startsWith(candleLinkPathPrefix)) return null;
  final payload = uri.queryParameters['d'];
  if (payload == null) return null;
  try {
    return utf8.decode(base64Url.decode(base64Url.normalize(payload)));
  } catch (_) {
    return null;
  }
}
