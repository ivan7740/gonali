import 'package:get_storage/get_storage.dart';

import 'package:unii_app/data/models/auth.dart';

/// Persists auth tokens locally.
///
/// W1 uses [GetStorage] for speed of iteration. W7 hardening replaces this
/// with `flutter_secure_storage` (Keychain / EncryptedSharedPreferences).
class TokenStorage {
  TokenStorage() : _box = GetStorage();

  final GetStorage _box;

  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _kUserId = 'user_id';

  /// Synchronous peek for use during app bootstrap (before DI resolves).
  static bool peekHasAccess() {
    final box = GetStorage();
    final v = box.read<String>(_kAccess);
    return v != null && v.isNotEmpty;
  }

  Future<void> save(TokensDto tokens) async {
    await _box.write(_kAccess, tokens.accessToken);
    await _box.write(_kRefresh, tokens.refreshToken);
    if (tokens.user != null) {
      await _box.write(_kUserId, tokens.user!.id);
    }
  }

  Future<void> saveAccess(String access) => _box.write(_kAccess, access);

  String? access() => _box.read<String>(_kAccess);

  String? refresh() => _box.read<String>(_kRefresh);

  int? userId() => _box.read<int>(_kUserId);

  bool get hasAccess => (access() ?? '').isNotEmpty;

  Future<void> clear() async {
    await _box.remove(_kAccess);
    await _box.remove(_kRefresh);
    await _box.remove(_kUserId);
  }
}
