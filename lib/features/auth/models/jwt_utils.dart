import 'dart:convert';
import 'dart:typed_data';

/// Extrait la date d'expiration d'un JWT (claim `exp`) de façon
/// sécurisée, sans ajouter de dépendance externe.
DateTime? jwtExpiry(String token) {
  final int? seconds = _jwtClaim(token, 'exp');
  return seconds != null
      ? DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true)
      : null;
}

/// Lit un claim numérique dans le payload d'un JWT.
int? _jwtClaim(String token, String claim) {
  try {
    final List<String> parts = token.split('.');
    if (parts.length < 3) return null;

    String payloadSeg = parts[1];
    final int remainder = payloadSeg.length % 4;
    if (remainder == 2) payloadSeg += '==';
    if (remainder == 3) payloadSeg += '=';

    final Uint8List decoded = base64Url.decode(payloadSeg);
    final String payload = utf8.decode(decoded);

    final Object? decodedJson = jsonDecode(payload);
    if (decodedJson is! Map<String, dynamic>) return null;

    final Object? value = decodedJson[claim];
    return value is num ? value.toInt() : null;
  } on FormatException {
    return null;
  } on RangeError {
    return null;
  }
}
