import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/models.dart';

/// Android-only local workspace. Web and desktop continue using the REST API.
class OfflineMobile {
  OfflineMobile._();
  static final instance = OfflineMobile._();
  static bool get enabled =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      const bool.fromEnvironment('OFFLINE_MOBILE', defaultValue: true);
  static const _channel = MethodChannel('abakascan/offline_v3');
  static const _profileKey = 'abakascan_offline_profile_v1';
  static const _storage = FlutterSecureStorage();
  final unlocked = ValueNotifier<bool>(false);
  UserModel? cachedUser;
  String? _origin;
  bool authenticating = false;

  Future<UserModel?> restore(String origin) async {
    final raw = await _storage.read(key: _profileKey);
    if (raw == null) return null;
    final saved = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    if (saved['origin'] != origin) return null;
    final user = UserModel.fromJson(
      Map<String, dynamic>.from(saved['user'] as Map),
    );
    if (!user.isUser || user.id <= 0) return null;
    cachedUser = user;
    _origin = origin;
    await unlock();
    return user;
  }

  Future<void> enroll(UserModel user, String origin) async {
    if (!user.isUser || user.id <= 0) return;
    // Cache only after a successful online login AND phone authentication.
    cachedUser = user;
    _origin = origin;
    try {
      await unlock();
      await _storage.write(
        key: _profileKey,
        value: jsonEncode({'origin': origin, 'user': user.toJson()}),
      );
    } catch (_) {
      cachedUser = null;
      _origin = null;
      await lock();
      rethrow;
    }
  }

  Future<void> unlock() async {
    if (authenticating) throw StateError('An unlock request is already open.');
    if (cachedUser == null || _origin == null) {
      throw StateError('Log in online once to set up this phone.');
    }
    authenticating = true;
    try {
      await _channel.invokeMethod('unlock', {
        'owner': '$_origin|${cachedUser!.id}',
      });
      unlocked.value = true;
    } catch (_) {
      unlocked.value = false;
      rethrow;
    } finally {
      authenticating = false;
    }
  }

  Future<void> lock() async {
    unlocked.value = false;
    await _channel.invokeMethod('lock');
  }

  Future<void> logout() async {
    unlocked.value = false;
    cachedUser = null;
    _origin = null;
    await _storage.delete(key: _profileKey);
    await _channel.invokeMethod('lock');
  }

  Future<dynamic> call(String method, [Map<String, dynamic>? args]) async {
    if (!unlocked.value) {
      throw StateError('Unlock this phone to access saved analyses.');
    }
    return _channel.invokeMethod(method, args);
  }

  Future<Uint8List> image(String id, {bool full = false}) async {
    final value = await call('image', {'id': id, 'full': full});
    return value as Uint8List;
  }

  Future<Map<String, dynamic>> selfTest() async =>
      Map<String, dynamic>.from(await call('selfTest') as Map);
}
