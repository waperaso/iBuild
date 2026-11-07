import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';

/// Letters are stored sealed: AES-256-GCM, a fresh random nonce for every value.
/// A sealed value reads `v1.` + base64(nonce + ciphertext + tag). The key comes
/// from MAIL_KEY (32 bytes, base64: `openssl rand -base64 32`). Lose the key and
/// the letters are gone, so it is kept with the other secrets and backed up
/// apart from the database.
class Vault {
  Vault._();

  static List<int>? _key;
  static bool development = true;
  static final _algorithm = AesGcm.with256bits();

  /// An empty [base64Key] means development: a fixed key, never for production.
  static void configure(String base64Key) {
    if (base64Key.isEmpty) {
      _key = sha256.convert(utf8.encode('ibuild-development-mail-key')).bytes;
      development = true;
      return;
    }
    _key = decodeKey(base64Key);
    development = false;
  }

  static List<int> decodeKey(String value) {
    final bytes = base64.decode(value.trim());
    if (bytes.length != 32) throw const FormatException('MAIL_KEY must be 32 bytes in base64');
    return bytes;
  }

  static bool validKey(String value) {
    try {
      decodeKey(value);
      return true;
    } catch (_) {
      return false;
    }
  }

  static List<int> get _secret => _key ?? (throw StateError('Vault is not configured'));

  static bool isSealed(String value) => value.startsWith('v1.');

  static Future<String> seal(String plain) async {
    final random = Random.secure();
    final nonce = List<int>.generate(12, (_) => random.nextInt(256));
    final box = await _algorithm.encrypt(utf8.encode(plain), secretKey: SecretKey(_secret), nonce: nonce);
    final out = BytesBuilder()
      ..add(nonce)
      ..add(box.cipherText)
      ..add(box.mac.bytes);
    return 'v1.${base64.encode(out.toBytes())}';
  }

  /// The text of a sealed value. A value that was never sealed is returned as it is.
  static Future<String> open(String value) async {
    if (!isSealed(value)) return value;
    final raw = base64.decode(value.substring(3));
    if (raw.length < 28) throw const FormatException('sealed value is too short');
    final box = SecretBox(
      raw.sublist(12, raw.length - 16),
      nonce: raw.sublist(0, 12),
      mac: Mac(raw.sublist(raw.length - 16)),
    );
    return utf8.decode(await _algorithm.decrypt(box, secretKey: SecretKey(_secret)));
  }
}
