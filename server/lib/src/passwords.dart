import 'dart:convert';
import 'dart:math';

import 'package:bcrypt/bcrypt.dart';
import 'package:crypto/crypto.dart';

String hashPassword(String password) =>
    BCrypt.hashpw(password, BCrypt.gensalt(logRounds: 8));

bool verifyPassword(String password, String hash) =>
    BCrypt.checkpw(password, hash);

/// Burned when the login does not exist, so the response time stays close
/// to a real password check.
final String dummyPasswordHash = hashPassword('dummy-not-a-user');

String randomToken() {
  final random = Random.secure();
  final bytes = List<int>.generate(32, (_) => random.nextInt(256));
  return base64Url.encode(bytes).replaceAll('=', '');
}

String sha256Hex(String value) => sha256.convert(utf8.encode(value)).toString();

bool tokensEqual(String left, String right) {
  final a = utf8.encode(left);
  final b = utf8.encode(right);
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}
