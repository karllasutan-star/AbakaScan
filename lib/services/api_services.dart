import 'package:flutter/services.dart';

import 'offline_mobile.dart';

import 'dart:async';

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/admin_models.dart';

import '../models/models.dart';

// ============================================================

// API CONFIGURATION

// ============================================================

class ApiConfig {
  const ApiConfig._();

  /// Default:

  /// Flutter Web / Windows on the same computer as FastAPI.

  ///

  /// Override it when running on another device using:

  ///

  /// flutter run --dart-define=API_BASE_URL=http://YOUR_IP:8000

  ///

  /// Android Emulator example:

  ///

  /// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',

    defaultValue: 'http://127.0.0.1:8000',
  );

  static const Duration timeout = Duration(seconds: 30);
}

// ============================================================

// API EXCEPTION

// ============================================================

class ApiException implements Exception {
  const ApiException({required this.message, this.statusCode, this.code});

  final String message;

  final int? statusCode;

  final String? code;

  @override
  String toString() {
    return message;
  }
}

// ============================================================

// API CLIENT

// ============================================================

class ApiClient {
  ApiClient({required String baseUrl, http.Client? client})
    : _baseUrl = _normalizeBaseUrl(baseUrl),

      _client = client ?? http.Client();

  final String _baseUrl;

  final http.Client _client;

  String get baseUrl => _baseUrl;

  Uri _uri(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';

    return Uri.parse('$_baseUrl$normalizedPath');
  }

  Map<String, String> _headers({String? token, bool json = true}) {
    if (token == 'offline-local') {
      throw const ApiException(
        message: 'Log in online again to access the server.',
        code: 'online_login_required',
      );
    }
    return {
      'Accept': 'application/json',

      if (json) 'Content-Type': 'application/json',

      if (token != null && token.trim().isNotEmpty)
        'Authorization': 'Bearer ${token.trim()}',
    };
  }

  Future<dynamic> get(String path, {String? token}) async {
    try {
      final response = await _client
          .get(_uri(path), headers: _headers(token: token))
          .timeout(ApiConfig.timeout);

      return _decodeResponse(response);
    } on TimeoutException {
      throw const ApiException(
        message: 'The server took too long to respond. Please try again.',
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message: 'Unable to connect to the ABAKASCAN server.',
      );
    }
  }

  Future<List<dynamic>> getCollection(String path, {String? token}) async {
    final data = await get(path, token: token);

    if (data is List) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      final possibleCollections = [
        data['items'],

        data['results'],

        data['records'],

        data['data'],

        data['users'],

        data['classifications'],
      ];

      for (final collection in possibleCollections) {
        if (collection is List) {
          return collection;
        }
      }
    }

    throw const ApiException(
      message: 'The server returned an invalid list response.',
    );
  }

  Future<dynamic> post(String path, {Object? body, String? token}) async {
    try {
      final response = await _client
          .post(
            _uri(path),

            headers: _headers(token: token),

            body: body == null ? null : jsonEncode(body),
          )
          .timeout(ApiConfig.timeout);

      return _decodeResponse(response);
    } on TimeoutException {
      throw const ApiException(
        message: 'The server took too long to respond. Please try again.',
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message: 'Unable to connect to the ABAKASCAN server.',
      );
    }
  }

  Future<dynamic> multipartPost(
    String path, {

    required Uint8List bytes,

    required String fileName,

    required String fieldName,

    String? token,

    Map<String, String>? fields,
  }) async {
    if (token == 'offline-local') {
      throw const ApiException(
        message: 'Log in online again to access the server.',
        code: 'online_login_required',
      );
    }
    try {
      final request = http.MultipartRequest('POST', _uri(path));

      request.headers['Accept'] = 'application/json';

      if (token != null && token.trim().isNotEmpty) {
        request.headers['Authorization'] = 'Bearer ${token.trim()}';
      }

      if (fields != null) {
        request.fields.addAll(fields);
      }

      request.files.add(
        http.MultipartFile.fromBytes(fieldName, bytes, filename: fileName),
      );

      final streamedResponse = await _client
          .send(request)
          .timeout(ApiConfig.timeout);

      final response = await http.Response.fromStream(streamedResponse);

      return _decodeResponse(response);
    } on TimeoutException {
      throw const ApiException(
        message: 'The image upload took too long. Please try again.',
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message: 'Unable to upload the image to the ABAKASCAN server.',
      );
    }
  }

  Future<dynamic> delete(String path, {String? token}) async {
    try {
      final response = await _client
          .delete(_uri(path), headers: _headers(token: token))
          .timeout(ApiConfig.timeout);

      return _decodeResponse(response);
    } on TimeoutException {
      throw const ApiException(
        message: 'The server took too long to respond. Please try again.',
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message: 'Unable to connect to the ABAKASCAN server.',
      );
    }
  }

  dynamic _decodeResponse(http.Response response) {
    final statusCode = response.statusCode;

    dynamic data;

    if (response.body.trim().isNotEmpty) {
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = response.body;
      }
    }

    if (statusCode >= 200 && statusCode < 300) {
      return data;
    }

    final detail = data is Map<String, dynamic> ? data['detail'] : null;

    throw ApiException(
      statusCode: statusCode,

      code: detail is Map<String, dynamic> ? detail['code']?.toString() : null,

      message: _extractErrorMessage(data, statusCode),
    );
  }

  String _extractErrorMessage(dynamic data, int statusCode) {
    if (data is Map<String, dynamic>) {
      final candidates = [data['detail'], data['message'], data['error']];

      for (final candidate in candidates) {
        if (candidate is Map<String, dynamic>) {
          final message = candidate['message'];

          if (message is String && message.trim().isNotEmpty) {
            return message.trim();
          }
        }

        if (candidate is String && candidate.trim().isNotEmpty) {
          return candidate.trim();
        }

        if (candidate is List && candidate.isNotEmpty) {
          return candidate.map((item) => item.toString()).join('\n');
        }
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    switch (statusCode) {
      case 400:
        return 'The request contains invalid information.';

      case 401:
        return 'Your session is invalid or has expired. Please log in again.';

      case 403:
        return 'You do not have permission to perform this action.';

      case 404:
        return 'The requested record or endpoint was not found.';

      case 409:
        return 'The request conflicts with an existing record.';

      case 422:
        return 'The submitted information could not be validated.';

      case 500:
        return 'The server encountered an unexpected error.';

      default:
        return 'Request failed with status code $statusCode.';
    }
  }

  void close() {
    _client.close();
  }

  static String _normalizeBaseUrl(String value) {
    var normalized = value.trim();

    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    return normalized;
  }
}

// ============================================================

// AUTH SERVICE

// ============================================================

class AuthService {
  AuthService(this._apiClient);

  final ApiClient _apiClient;

  Future<AuthResult> login(LoginRequest request) async {
    final data = await _apiClient.post('/login', body: request.toJson());

    return _authResultFromResponse(data);
  }

  Future<RegistrationPendingResponse> register(RegisterRequest request) async {
    final data = await _apiClient.post('/register', body: request.toJson());

    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'The registration response is invalid.',
      );
    }

    return RegistrationPendingResponse.fromJson(data);
  }

  Future<EmailVerificationResponse> verifyEmail(
    VerifyEmailRequest request,
  ) async {
    final data = await _apiClient.post('/verify-email', body: request.toJson());

    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'The email verification response is invalid.',
      );
    }

    return EmailVerificationResponse.fromJson(data);
  }

  Future<EmailVerificationResponse> resendVerification(
    ResendVerificationRequest request,
  ) async {
    final data = await _apiClient.post(
      '/resend-verification',

      body: request.toJson(),
    );

    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'The resend verification response is invalid.',
      );
    }

    return EmailVerificationResponse.fromJson(data);
  }

  Future<PasswordResetResponse> forgotPassword(
    ForgotPasswordRequest request,
  ) async {
    final data = await _apiClient.post(
      '/forgot-password',

      body: request.toJson(),
    );

    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'The server returned an invalid password reset response.',
      );
    }

    return PasswordResetResponse.fromJson(data);
  }

  Future<PasswordResetResponse> resetPassword(
    ResetPasswordRequest request,
  ) async {
    final data = await _apiClient.post(
      '/reset-password',

      body: request.toJson(),
    );

    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'The server returned an invalid password reset response.',
      );
    }

    return PasswordResetResponse.fromJson(data);
  }

  Future<UserModel> getProfile(String token) async {
    if (OfflineMobile.enabled && OfflineMobile.instance.cachedUser != null) {
      if (!OfflineMobile.instance.unlocked.value) {
        throw const ApiException(
          message: 'Unlock this phone to access your account.',
        );
      }
      return OfflineMobile.instance.cachedUser!;
    }
    final data = await _apiClient.get('/profile', token: token);

    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'The server returned an invalid profile response.',
      );
    }

    final userData = _unwrapMap(data, const ['user', 'profile', 'data']);

    return UserModel.fromJson(userData);
  }

  AuthResult _authResultFromResponse(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'The authentication response is invalid.',
      );
    }

    return AuthResult.fromJson(data);
  }
}

// ============================================================

// CLASSIFICATION SERVICE

// ============================================================

class ClassificationService {
  ClassificationService(this._apiClient);

  final ApiClient _apiClient;

  Future<ClassificationResultModel> classify({
    required String token,

    required Uint8List imageBytes,

    required String fileName,
  }) async {
    if (OfflineMobile.enabled) {
      final data = await _local('classify', {
        'bytes': imageBytes,
        'fileName': fileName,
      });
      return ClassificationResultModel.fromJson(
        Map<String, dynamic>.from(data as Map),
      );
    }
    dynamic data;

    try {
      data = await _apiClient.multipartPost(
        '/classifications',

        token: token,

        bytes: imageBytes,

        fileName: fileName,

        fieldName: 'image',
      );
    } on ApiException catch (error) {
      if (error.statusCode == 400 &&
          (error.code == 'unidentified_object' ||
              error.code == 'multiple_bundles' ||
              error.code == 'uncertain_grade')) {
        return ClassificationResultModel(
          predictedGrade: '',

          confidence: 0,

          savedToHistory: false,

          detectionStatus: error.code!,

          detectionMessage: error.message,
        );
      }

      rethrow;
    }

    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'The server returned an invalid classification response.',
      );
    }

    final resultData = _unwrapMap(data, const [
      'classification',

      'result',

      'data',
    ]);

    return ClassificationResultModel.fromJson(resultData);
  }

  Future<List<ClassificationRecordModel>> getHistory(String token) async {
    if (OfflineMobile.enabled) {
      final data = await _local('history') as List;
      return data
          .map(
            (item) => ClassificationRecordModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    }
    final data = await _apiClient.getCollection(
      '/classifications',

      token: token,
    );

    return data
        .whereType<Map<String, dynamic>>()
        .map(ClassificationRecordModel.fromJson)
        .toList();
  }

  Future<ClassificationRecordModel> getClassification({
    required String token,

    required String classificationId,
  }) async {
    if (OfflineMobile.enabled) {
      final data = await _local('get', {'id': classificationId});
      return ClassificationRecordModel.fromJson(
        Map<String, dynamic>.from(data as Map),
      );
    }
    final data = await _apiClient.get(
      '/classifications/$classificationId',

      token: token,
    );

    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'The server returned an invalid classification record.',
      );
    }

    final recordData = _unwrapMap(data, const [
      'classification',

      'record',

      'data',
    ]);

    return ClassificationRecordModel.fromJson(recordData);
  }

  Future<void> deleteClassification({
    required String token,

    required String classificationId,
  }) async {
    if (OfflineMobile.enabled) {
      await _local('delete', {'id': classificationId});
      return;
    }
    await _apiClient.delete('/classifications/$classificationId', token: token);
  }

  Future<dynamic> _local(String method, [Map<String, dynamic>? args]) async {
    try {
      return await OfflineMobile.instance.call(method, args);
    } on PlatformException catch (error) {
      throw ApiException(
        message: error.message ?? 'Offline operation failed.',
        code: error.code,
      );
    } on StateError catch (error) {
      throw ApiException(
        message: error.message.toString(),
        code: 'local_locked',
      );
    }
  }
}

// ============================================================

// ADMIN SERVICE

// ============================================================

class AdminService {
  AdminService(this._apiClient);

  final ApiClient _apiClient;

  Future<AdminOverviewModel> getOverview(String token) async {
    final data = await _apiClient.get('/admin/overview', token: token);

    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        message: 'The server returned an invalid administrator overview.',
      );
    }

    final overviewData = _unwrapMap(data, const ['overview', 'data']);

    return AdminOverviewModel.fromJson(overviewData);
  }

  Future<List<AdminUserModel>> getUsers(String token) async {
    final data = await _apiClient.getCollection('/admin/users', token: token);

    return data
        .whereType<Map<String, dynamic>>()
        .map(AdminUserModel.fromJson)
        .toList();
  }

  Future<AdminUserModel?> createAdministrator({
    required String token,

    required CreateAdminRequest request,
  }) async {
    final data = await _apiClient.post(
      '/admin/admins',

      token: token,

      body: request.toJson(),
    );

    if (data == null) {
      return null;
    }

    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        message:
            'The server returned an invalid administrator account response.',
      );
    }

    final adminData = _unwrapMap(data, const ['admin', 'user', 'data']);

    return AdminUserModel.fromJson(adminData);
  }

  Future<List<AdminClassificationRecordModel>> getClassifications(
    String token,
  ) async {
    final data = await _apiClient.getCollection(
      '/admin/classifications',

      token: token,
    );

    return data
        .whereType<Map<String, dynamic>>()
        .map(AdminClassificationRecordModel.fromJson)
        .toList();
  }
}

// ============================================================

// RESPONSE HELPERS

// ============================================================

Map<String, dynamic> _unwrapMap(
  Map<String, dynamic> source,

  List<String> possibleKeys,
) {
  for (final key in possibleKeys) {
    final value = source[key];

    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
  }

  return source;
}
