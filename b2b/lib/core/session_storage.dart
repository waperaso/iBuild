import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Auth/session persistence. [FlutterSecureStorage] needs a secure context
/// (HTTPS or localhost); plain HTTP staging on an IP throws after OTP verify.
class SessionStorage {
  SessionStorage._(this._secure, this._prefs);

  final FlutterSecureStorage _secure;
  final SharedPreferences? _prefs;

  static Future<SessionStorage> open() async {
    if (kIsWeb) {
      return SessionStorage._(
        const FlutterSecureStorage(),
        await SharedPreferences.getInstance(),
      );
    }
    return SessionStorage._(const FlutterSecureStorage(), null);
  }

  Future<String?> read({required String key}) {
    final prefs = _prefs;
    if (prefs != null) return Future.value(prefs.getString(key));
    return _secure.read(key: key);
  }

  Future<void> write({required String key, required String value}) {
    final prefs = _prefs;
    if (prefs != null) return prefs.setString(key, value);
    return _secure.write(key: key, value: value);
  }

  Future<void> delete({required String key}) {
    final prefs = _prefs;
    if (prefs != null) return prefs.remove(key);
    return _secure.delete(key: key);
  }
}

/// Set in [main] before [runApp]; read via [sessionStorageProvider].
SessionStorage? globalSessionStorage;

final sessionStorageProvider = Provider<SessionStorage>((ref) {
  final storage = globalSessionStorage;
  if (storage == null) {
    throw StateError('SessionStorage not initialized — call main() first');
  }
  return storage;
});
