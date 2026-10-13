import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../models/admin_models.dart';
import '../models/models.dart';
import '../services/api_services.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, failure }

enum AuthDestination { publicHome, userDashboard, adminDashboard }

enum SelectedImageSource { webUpload, mobileCamera, mobileGallery }

enum ClassificationStatus { initial, analyzing, success, failure }

enum HistoryStatus { initial, loading, success, failure }

// ============================================================
// AUTH PROVIDER
// ============================================================

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService, {FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'abakascan_auth_token';

  final AuthService _authService;
  final FlutterSecureStorage _secureStorage;

  AuthStatus _status = AuthStatus.initial;

  UserModel? _currentUser;
  String? _token;

  bool _sessionInitializing = false;
  bool _loginLoading = false;
  bool _registerLoading = false;

  String? _loginError;
  String? _registerError;
  String? _sessionMessage;
  String? _registrationMessage;

  int? _errorStatusCode;

  AuthStatus get status => _status;

  UserModel? get currentUser => _currentUser;

  String? get token => _token;

  bool get sessionInitializing => _sessionInitializing;

  bool get loginLoading => _loginLoading;

  bool get registerLoading => _registerLoading;

  String? get loginError => _loginError;

  String? get registerError => _registerError;

  String? get sessionMessage => _sessionMessage;

  String? get registrationMessage => _registrationMessage;

  int? get errorStatusCode => _errorStatusCode;

  bool get isLoading =>
      _sessionInitializing || _loginLoading || _registerLoading;

  bool get isAuthenticated =>
      _status == AuthStatus.authenticated &&
      _token != null &&
      _token!.trim().isNotEmpty &&
      _currentUser != null;

  bool get isAdmin => isAuthenticated && _currentUser!.isAdmin;

  bool get isUser => isAuthenticated && _currentUser!.isUser;

  bool get sessionExpired => _errorStatusCode == 401 || _errorStatusCode == 403;

  AuthDestination get destination {
    if (!isAuthenticated) {
      return AuthDestination.publicHome;
    }

    if (isAdmin) {
      return AuthDestination.adminDashboard;
    }

    return AuthDestination.userDashboard;
  }

  Future<void> initializeSession() async {
    if (_sessionInitializing) {
      return;
    }

    _sessionInitializing = true;
    _status = AuthStatus.loading;

    _sessionMessage = null;
    _errorStatusCode = null;

    notifyListeners();

    try {
      final storedToken = await _secureStorage.read(key: _tokenKey);

      if (storedToken == null || storedToken.trim().isEmpty) {
        _clearAuthenticationState();

        _status = AuthStatus.unauthenticated;

        return;
      }

      _token = storedToken;

      final dynamic service = _authService;

      final dynamic result = await service.getProfile(storedToken);

      if (result is! UserModel) {
        throw StateError('The profile response is invalid.');
      }

      _currentUser = result;

      _status = AuthStatus.authenticated;

      _sessionMessage = null;
      _errorStatusCode = null;
    } catch (error) {
      _errorStatusCode = _statusCodeFromError(error);

      await _secureStorage.delete(key: _tokenKey);

      _clearAuthenticationState();

      _sessionMessage =
          'Your previous session could not be restored. Please log in again.';

      _status = AuthStatus.unauthenticated;
    } finally {
      _sessionInitializing = false;

      notifyListeners();
    }
  }

  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    if (_loginLoading) {
      return false;
    }

    final normalizedIdentifier = identifier.trim();

    if (normalizedIdentifier.isEmpty) {
      _loginError = 'Email or username is required.';

      notifyListeners();

      return false;
    }

    if (password.isEmpty) {
      _loginError = 'Password is required.';

      notifyListeners();

      return false;
    }

    _loginLoading = true;

    _loginError = null;
    _registerError = null;
    _sessionMessage = null;
    _registrationMessage = null;
    _errorStatusCode = null;

    notifyListeners();

    try {
      final request = LoginRequest(
        identifier: normalizedIdentifier,
        password: password,
      );

      final dynamic service = _authService;

      final dynamic result = await service.login(request);

      if (result is! AuthResult) {
        throw StateError('The login response is invalid.');
      }

      if (result.token.trim().isEmpty) {
        throw StateError('The server did not return an authentication token.');
      }

      _token = result.token;
      _currentUser = result.user;

      await _secureStorage.write(key: _tokenKey, value: result.token);

      _status = AuthStatus.authenticated;

      _errorStatusCode = null;

      return true;
    } catch (error) {
      _loginError = _friendlyError(
        error,
        fallback:
            'Unable to log in. Please check your credentials and try again.',
      );

      _errorStatusCode = _statusCodeFromError(error);

      _status = AuthStatus.unauthenticated;

      return false;
    } finally {
      _loginLoading = false;

      notifyListeners();
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required StakeholderRole stakeholderRole,
    String? customRole,
  }) async {
    if (_registerLoading) {
      return false;
    }

    final normalizedName = fullName.trim();

    final normalizedEmail = email.trim();

    final normalizedCustomRole = customRole?.trim();

    if (normalizedName.isEmpty) {
      _registerError = 'Full name is required.';

      notifyListeners();

      return false;
    }

    if (normalizedEmail.isEmpty) {
      _registerError = 'Email address is required.';

      notifyListeners();

      return false;
    }

    if (password.isEmpty) {
      _registerError = 'Password is required.';

      notifyListeners();

      return false;
    }

    if (stakeholderRole == StakeholderRole.others &&
        (normalizedCustomRole == null || normalizedCustomRole.isEmpty)) {
      _registerError = 'Please specify your stakeholder role.';

      notifyListeners();

      return false;
    }

    _registerLoading = true;

    _registerError = null;
    _loginError = null;
    _sessionMessage = null;
    _registrationMessage = null;
    _errorStatusCode = null;

    notifyListeners();

    try {
      final request = RegisterRequest(
        fullName: normalizedName,
        email: normalizedEmail,
        password: password,
        stakeholderRole: stakeholderRole,
        customRole: normalizedCustomRole,
      );

      final dynamic service = _authService;

      final dynamic result = await service.register(request);

      if (result is! AuthResult) {
        throw StateError('The registration response is invalid.');
      }

      if (result.token.trim().isEmpty) {
        throw StateError('The server did not return an authentication token.');
      }

      _token = result.token;
      _currentUser = result.user;

      await _secureStorage.write(key: _tokenKey, value: result.token);

      _registrationMessage = 'Account created successfully.';

      _status = AuthStatus.authenticated;

      _errorStatusCode = null;

      return true;
    } catch (error) {
      _registerError = _friendlyError(
        error,
        fallback: 'Unable to create your account. Please try again.',
      );

      _errorStatusCode = _statusCodeFromError(error);

      _status = AuthStatus.unauthenticated;

      return false;
    } finally {
      _registerLoading = false;

      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: _tokenKey);

    _clearAuthenticationState();

    _loginLoading = false;
    _registerLoading = false;
    _sessionInitializing = false;

    _loginError = null;
    _registerError = null;
    _registrationMessage = null;
    _sessionMessage = null;

    _status = AuthStatus.unauthenticated;

    notifyListeners();
  }

  Future<void> expireSession() async {
    await _secureStorage.delete(key: _tokenKey);

    _clearAuthenticationState();

    _loginLoading = false;
    _registerLoading = false;
    _sessionInitializing = false;

    _loginError = null;
    _registerError = null;
    _registrationMessage = null;

    _sessionMessage = 'Your session has expired. Please log in again.';

    _status = AuthStatus.unauthenticated;

    notifyListeners();
  }

  void clearLoginError() {
    if (_loginError == null) {
      return;
    }

    _loginError = null;

    notifyListeners();
  }

  void clearRegisterError() {
    if (_registerError == null) {
      return;
    }

    _registerError = null;

    notifyListeners();
  }

  void clearSessionMessage() {
    if (_sessionMessage == null) {
      return;
    }

    _sessionMessage = null;

    notifyListeners();
  }

  void clearRegistrationMessage() {
    if (_registrationMessage == null) {
      return;
    }

    _registrationMessage = null;

    notifyListeners();
  }

  void _clearAuthenticationState() {
    _token = null;
    _currentUser = null;
    _errorStatusCode = null;
  }
}

// ============================================================
// IMAGE SELECTION PROVIDER
// ============================================================

class ImageSelectionProvider extends ChangeNotifier {
  ImageSelectionProvider({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  XFile? _selectedImage;

  Uint8List? _selectedImageBytes;

  SelectedImageSource? _source;

  bool _loading = false;

  String? _error;

  XFile? get selectedImage => _selectedImage;

  Uint8List? get selectedImageBytes => _selectedImageBytes;

  SelectedImageSource? get source => _source;

  bool get loading => _loading;

  String? get error => _error;

  bool get hasImage =>
      _selectedImage != null &&
      _selectedImageBytes != null &&
      _selectedImageBytes!.isNotEmpty;

  String? get fileName => _selectedImage?.name;

  Future<bool> chooseImage() async {
    if (_loading) {
      return false;
    }

    _loading = true;
    _error = null;

    notifyListeners();

    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery);

      if (image == null) {
        return false;
      }

      return await _prepareImage(
        image,
        source: kIsWeb
            ? SelectedImageSource.webUpload
            : SelectedImageSource.mobileGallery,
      );
    } catch (_) {
      _error = 'Unable to open the selected image.';

      return false;
    } finally {
      _loading = false;

      notifyListeners();
    }
  }

  Future<bool> captureImage() async {
    if (_loading) {
      return false;
    }

    if (kIsWeb) {
      _error = 'Camera capture is available on the mobile application.';

      notifyListeners();

      return false;
    }

    _loading = true;
    _error = null;

    notifyListeners();

    try {
      final image = await _imagePicker.pickImage(source: ImageSource.camera);

      if (image == null) {
        return false;
      }

      return await _prepareImage(
        image,
        source: SelectedImageSource.mobileCamera,
      );
    } catch (_) {
      _error = 'Unable to capture the image.';

      return false;
    } finally {
      _loading = false;

      notifyListeners();
    }
  }

  Future<bool> _prepareImage(
    XFile image, {
    required SelectedImageSource source,
  }) async {
    final extension = _fileExtension(image.name);

    const supportedExtensions = {'jpg', 'jpeg', 'png'};

    if (!supportedExtensions.contains(extension)) {
      _error = 'Unsupported image format. Please use JPG, JPEG, or PNG.';

      return false;
    }

    try {
      final bytes = await image.readAsBytes();

      if (bytes.isEmpty) {
        _error = 'The selected image could not be read.';

        return false;
      }

      _selectedImage = image;

      _selectedImageBytes = bytes;

      _source = source;

      _error = null;

      return true;
    } catch (_) {
      _error = 'The selected image could not be read.';

      return false;
    }
  }

  void removeImage() {
    _selectedImage = null;
    _selectedImageBytes = null;
    _source = null;
    _error = null;
    _loading = false;

    notifyListeners();
  }

  void clear() {
    removeImage();
  }

  void clearError() {
    if (_error == null) {
      return;
    }

    _error = null;

    notifyListeners();
  }
}

// ============================================================
// CLASSIFICATION PROVIDER
// ============================================================

class ClassificationProvider extends ChangeNotifier {
  ClassificationProvider(this._classificationService);

  final ClassificationService _classificationService;

  ClassificationStatus _status = ClassificationStatus.initial;

  ClassificationResultModel? _result;

  String? _error;

  int? _errorStatusCode;

  ClassificationStatus get status => _status;

  ClassificationResultModel? get result => _result;

  String? get error => _error;

  int? get errorStatusCode => _errorStatusCode;

  bool get isAnalyzing => _status == ClassificationStatus.analyzing;

  bool get hasResult =>
      _status == ClassificationStatus.success && _result != null;

  bool get hasError => _status == ClassificationStatus.failure;

  bool get sessionExpired => _errorStatusCode == 401 || _errorStatusCode == 403;

  Future<bool> classify({
    required String token,
    required Uint8List imageBytes,
    required String fileName,
  }) async {
    if (_status == ClassificationStatus.analyzing) {
      return false;
    }

    if (token.trim().isEmpty) {
      _status = ClassificationStatus.failure;

      _error = 'You must be logged in before classifying an image.';

      _errorStatusCode = 401;

      notifyListeners();

      return false;
    }

    if (imageBytes.isEmpty) {
      _status = ClassificationStatus.failure;

      _error = 'The selected image is empty or unreadable.';

      _errorStatusCode = null;

      notifyListeners();

      return false;
    }

    _status = ClassificationStatus.analyzing;

    _result = null;
    _error = null;
    _errorStatusCode = null;

    notifyListeners();

    try {
      final dynamic service = _classificationService;

      final dynamic result = await service.classify(
        token: token,
        imageBytes: imageBytes,
        fileName: fileName,
      );

      if (result is! ClassificationResultModel) {
        throw StateError('The classification response is invalid.');
      }

      _result = result;

      _status = ClassificationStatus.success;

      return true;
    } catch (error) {
      _error = _friendlyError(
        error,
        fallback: 'Unable to classify the image. Please try again.',
      );

      _errorStatusCode = _statusCodeFromError(error);

      _status = ClassificationStatus.failure;

      return false;
    } finally {
      notifyListeners();
    }
  }

  void clearError() {
    if (_error == null && _errorStatusCode == null) {
      return;
    }

    _error = null;
    _errorStatusCode = null;

    if (_result == null) {
      _status = ClassificationStatus.initial;
    }

    notifyListeners();
  }

  void reset() {
    _status = ClassificationStatus.initial;

    _result = null;
    _error = null;
    _errorStatusCode = null;

    notifyListeners();
  }

  void clear() {
    reset();
  }
}

// ============================================================
// HISTORY PROVIDER
// ============================================================

class HistoryProvider extends ChangeNotifier {
  HistoryProvider(this._classificationService);

  final ClassificationService _classificationService;

  final List<ClassificationRecordModel> _records = [];

  final Set<String> _deletingIds = {};

  HistoryStatus _status = HistoryStatus.initial;

  String? _error;

  int? _errorStatusCode;

  List<ClassificationRecordModel> get records => List.unmodifiable(_records);

  Set<String> get deletingIds => Set.unmodifiable(_deletingIds);

  HistoryStatus get status => _status;

  String? get error => _error;

  int? get errorStatusCode => _errorStatusCode;

  bool get isLoading => _status == HistoryStatus.loading;

  bool get hasError => _status == HistoryStatus.failure;

  bool get hasRecords => _records.isNotEmpty;

  int get totalRecords => _records.length;

  ClassificationRecordModel? get latestRecord =>
      _records.isEmpty ? null : _records.first;

  bool get sessionExpired => _errorStatusCode == 401 || _errorStatusCode == 403;

  bool isDeleting(String classificationId) {
    return _deletingIds.contains(classificationId);
  }

  Future<bool> loadHistory({required String token}) async {
    if (token.trim().isEmpty) {
      _status = HistoryStatus.failure;

      _error = 'Authentication is required to view classification history.';

      _errorStatusCode = 401;

      notifyListeners();

      return false;
    }

    _status = HistoryStatus.loading;

    _error = null;
    _errorStatusCode = null;

    notifyListeners();

    return _fetchHistory(token: token);
  }

  Future<bool> refreshHistory({required String token}) async {
    if (token.trim().isEmpty) {
      _error = 'Authentication is required to refresh classification history.';

      _errorStatusCode = 401;

      if (_records.isEmpty) {
        _status = HistoryStatus.failure;
      }

      notifyListeners();

      return false;
    }

    if (_records.isEmpty) {
      _status = HistoryStatus.loading;
    }

    _error = null;
    _errorStatusCode = null;

    notifyListeners();

    return _fetchHistory(token: token);
  }

  Future<bool> _fetchHistory({required String token}) async {
    try {
      final dynamic service = _classificationService;

      final dynamic result = await service.getHistory(token);

      if (result is List<ClassificationRecordModel>) {
        _records
          ..clear()
          ..addAll(result);
      } else if (result is List) {
        _records
          ..clear()
          ..addAll(result.whereType<ClassificationRecordModel>());
      } else {
        throw StateError('The history response is invalid.');
      }

      _sortRecords();

      _status = HistoryStatus.success;

      _error = null;
      _errorStatusCode = null;

      notifyListeners();

      return true;
    } catch (error) {
      _error = _friendlyError(
        error,
        fallback: 'Unable to load your classification history.',
      );

      _errorStatusCode = _statusCodeFromError(error);

      if (_records.isEmpty) {
        _status = HistoryStatus.failure;
      } else {
        _status = HistoryStatus.success;
      }

      notifyListeners();

      return false;
    }
  }

  Future<bool> deleteClassification({
    required String token,
    required String classificationId,
  }) async {
    if (token.trim().isEmpty) {
      _error = 'Authentication is required to delete a classification record.';

      _errorStatusCode = 401;

      notifyListeners();

      return false;
    }

    final normalizedId = classificationId.trim();

    if (normalizedId.isEmpty) {
      _error = 'The classification record ID is invalid.';

      _errorStatusCode = null;

      notifyListeners();

      return false;
    }

    if (_deletingIds.contains(normalizedId)) {
      return false;
    }

    _deletingIds.add(normalizedId);

    _error = null;
    _errorStatusCode = null;

    notifyListeners();

    try {
      final dynamic service = _classificationService;

      await service.deleteClassification(
        token: token,
        classificationId: normalizedId,
      );

      _records.removeWhere((record) => record.id == normalizedId);

      _deletingIds.remove(normalizedId);

      _status = HistoryStatus.success;

      notifyListeners();

      return true;
    } catch (error) {
      _deletingIds.remove(normalizedId);

      _error = _friendlyError(
        error,
        fallback: 'Unable to delete the classification record.',
      );

      _errorStatusCode = _statusCodeFromError(error);

      notifyListeners();

      return false;
    }
  }

  void clearError() {
    if (_error == null && _errorStatusCode == null) {
      return;
    }

    _error = null;
    _errorStatusCode = null;

    if (_records.isNotEmpty) {
      _status = HistoryStatus.success;
    } else if (_status == HistoryStatus.failure) {
      _status = HistoryStatus.initial;
    }

    notifyListeners();
  }

  void reset() {
    _records.clear();
    _deletingIds.clear();

    _status = HistoryStatus.initial;

    _error = null;
    _errorStatusCode = null;

    notifyListeners();
  }

  void _sortRecords() {
    _records.sort(
      (first, second) => second.createdAt.compareTo(first.createdAt),
    );
  }
}

// ============================================================
// ADMIN PROVIDER
// ============================================================

class AdminProvider extends ChangeNotifier {
  AdminProvider(this._adminService);

  final AdminService _adminService;

  AdminOverviewModel? _overview;

  final List<AdminUserModel> _users = [];

  final List<AdminClassificationRecordModel> _classificationRecords = [];

  AdminUserModel? _lastCreatedAdmin;

  bool _overviewLoading = false;

  bool _usersLoading = false;

  bool _classificationsLoading = false;

  bool _creatingAdmin = false;

  String? _overviewError;

  String? _usersError;

  String? _classificationsError;

  String? _createAdminError;

  int? _overviewErrorStatusCode;

  int? _usersErrorStatusCode;

  int? _classificationsErrorStatusCode;

  int? _createAdminErrorStatusCode;

  AdminOverviewModel? get overview => _overview;

  List<AdminUserModel> get users => List.unmodifiable(_users);

  List<AdminClassificationRecordModel> get classificationRecords =>
      List.unmodifiable(_classificationRecords);

  AdminUserModel? get lastCreatedAdmin => _lastCreatedAdmin;

  bool get overviewLoading => _overviewLoading;

  bool get usersLoading => _usersLoading;

  bool get classificationsLoading => _classificationsLoading;

  bool get creatingAdmin => _creatingAdmin;

  String? get overviewError => _overviewError;

  String? get usersError => _usersError;

  String? get classificationsError => _classificationsError;

  String? get createAdminError => _createAdminError;

  List<AdminUserModel> get regularUsers =>
      List.unmodifiable(_users.where((user) => user.isRegularUser).toList());

  List<AdminUserModel> get admins =>
      List.unmodifiable(_users.where((user) => user.isAdmin).toList());

  AdminClassificationRecordModel? get latestClassification =>
      _classificationRecords.isEmpty ? null : _classificationRecords.first;

  bool get sessionExpired =>
      _overviewErrorStatusCode == 401 ||
      _overviewErrorStatusCode == 403 ||
      _usersErrorStatusCode == 401 ||
      _usersErrorStatusCode == 403 ||
      _classificationsErrorStatusCode == 401 ||
      _classificationsErrorStatusCode == 403 ||
      _createAdminErrorStatusCode == 401 ||
      _createAdminErrorStatusCode == 403;

  Future<void> loadAll({required String token}) async {
    await Future.wait([
      loadOverview(token: token),
      loadUsers(token: token),
      loadClassifications(token: token),
    ]);
  }

  Future<void> refreshAll({required String token}) async {
    await loadAll(token: token);
  }

  Future<bool> loadOverview({required String token}) async {
    if (token.trim().isEmpty) {
      _overviewError = 'Administrator authentication is required.';

      _overviewErrorStatusCode = 401;

      notifyListeners();

      return false;
    }

    _overviewLoading = true;

    _overviewError = null;
    _overviewErrorStatusCode = null;

    notifyListeners();

    try {
      final dynamic service = _adminService;

      final dynamic result = await service.getOverview(token);

      if (result is! AdminOverviewModel) {
        throw StateError('The administrator overview response is invalid.');
      }

      _overview = result;

      return true;
    } catch (error) {
      _overviewError = _friendlyError(
        error,
        fallback: 'Unable to load administrator statistics.',
      );

      _overviewErrorStatusCode = _statusCodeFromError(error);

      return false;
    } finally {
      _overviewLoading = false;

      notifyListeners();
    }
  }

  Future<bool> loadUsers({required String token}) async {
    if (token.trim().isEmpty) {
      _usersError = 'Administrator authentication is required.';

      _usersErrorStatusCode = 401;

      notifyListeners();

      return false;
    }

    _usersLoading = true;

    _usersError = null;
    _usersErrorStatusCode = null;

    notifyListeners();

    try {
      final dynamic service = _adminService;

      final dynamic result = await service.getUsers(token);

      if (result is List<AdminUserModel>) {
        _users
          ..clear()
          ..addAll(result);
      } else if (result is List) {
        _users
          ..clear()
          ..addAll(result.whereType<AdminUserModel>());
      } else {
        throw StateError('The account response is invalid.');
      }

      _users.sort(
        (first, second) => first.fullName.toLowerCase().compareTo(
          second.fullName.toLowerCase(),
        ),
      );

      return true;
    } catch (error) {
      _usersError = _friendlyError(
        error,
        fallback: 'Unable to load registered accounts.',
      );

      _usersErrorStatusCode = _statusCodeFromError(error);

      return false;
    } finally {
      _usersLoading = false;

      notifyListeners();
    }
  }

  Future<bool> loadClassifications({required String token}) async {
    if (token.trim().isEmpty) {
      _classificationsError = 'Administrator authentication is required.';

      _classificationsErrorStatusCode = 401;

      notifyListeners();

      return false;
    }

    _classificationsLoading = true;

    _classificationsError = null;

    _classificationsErrorStatusCode = null;

    notifyListeners();

    try {
      final dynamic service = _adminService;

      final dynamic result = await service.getClassifications(token);

      if (result is List<AdminClassificationRecordModel>) {
        _classificationRecords
          ..clear()
          ..addAll(result);
      } else if (result is List) {
        _classificationRecords
          ..clear()
          ..addAll(result.whereType<AdminClassificationRecordModel>());
      } else {
        throw StateError(
          'The administrator classification response is invalid.',
        );
      }

      _classificationRecords.sort(
        (first, second) => second.createdAt.compareTo(first.createdAt),
      );

      return true;
    } catch (error) {
      _classificationsError = _friendlyError(
        error,
        fallback: 'Unable to load classification records.',
      );

      _classificationsErrorStatusCode = _statusCodeFromError(error);

      return false;
    } finally {
      _classificationsLoading = false;

      notifyListeners();
    }
  }

  Future<bool> createAdministrator({
    required String token,
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (_creatingAdmin) {
      return false;
    }

    if (token.trim().isEmpty) {
      _createAdminError = 'Administrator authentication is required.';

      _createAdminErrorStatusCode = 401;

      notifyListeners();

      return false;
    }

    _creatingAdmin = true;

    _createAdminError = null;

    _createAdminErrorStatusCode = null;

    notifyListeners();

    try {
      final request = CreateAdminRequest(
        fullName: fullName.trim(),
        email: email.trim(),
        password: password,
      );

      final dynamic service = _adminService;

      final dynamic result = await service.createAdministrator(
        token: token,
        request: request,
      );

      if (result is AdminUserModel) {
        _lastCreatedAdmin = result;

        final existingIndex = _users.indexWhere((user) => user.id == result.id);

        if (existingIndex >= 0) {
          _users[existingIndex] = result;
        } else {
          _users.insert(0, result);
        }
      }

      return true;
    } catch (error) {
      _createAdminError = _friendlyError(
        error,
        fallback: 'Unable to create the administrator account.',
      );

      _createAdminErrorStatusCode = _statusCodeFromError(error);

      return false;
    } finally {
      _creatingAdmin = false;

      notifyListeners();
    }
  }

  void clearOverviewError() {
    if (_overviewError == null && _overviewErrorStatusCode == null) {
      return;
    }

    _overviewError = null;
    _overviewErrorStatusCode = null;

    notifyListeners();
  }

  void clearUsersError() {
    if (_usersError == null && _usersErrorStatusCode == null) {
      return;
    }

    _usersError = null;
    _usersErrorStatusCode = null;

    notifyListeners();
  }

  void clearClassificationsError() {
    if (_classificationsError == null &&
        _classificationsErrorStatusCode == null) {
      return;
    }

    _classificationsError = null;

    _classificationsErrorStatusCode = null;

    notifyListeners();
  }

  void clearCreateAdminError() {
    if (_createAdminError == null && _createAdminErrorStatusCode == null) {
      return;
    }

    _createAdminError = null;

    _createAdminErrorStatusCode = null;

    notifyListeners();
  }

  void reset() {
    _overview = null;

    _users.clear();

    _classificationRecords.clear();

    _lastCreatedAdmin = null;

    _overviewLoading = false;
    _usersLoading = false;
    _classificationsLoading = false;
    _creatingAdmin = false;

    _overviewError = null;
    _usersError = null;
    _classificationsError = null;
    _createAdminError = null;

    _overviewErrorStatusCode = null;
    _usersErrorStatusCode = null;

    _classificationsErrorStatusCode = null;

    _createAdminErrorStatusCode = null;

    notifyListeners();
  }
}

// ============================================================
// HELPERS
// ============================================================

String _fileExtension(String fileName) {
  final normalized = fileName.trim().toLowerCase();

  final dotIndex = normalized.lastIndexOf('.');

  if (dotIndex < 0 || dotIndex == normalized.length - 1) {
    return '';
  }

  return normalized.substring(dotIndex + 1);
}

int? _statusCodeFromError(Object error) {
  try {
    final dynamic dynamicError = error;

    final dynamic value = dynamicError.statusCode;

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }
  } catch (_) {
    // No status code is available.
  }

  return null;
}

String _friendlyError(Object error, {required String fallback}) {
  try {
    final dynamic dynamicError = error;

    final dynamic message = dynamicError.message;

    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
  } catch (_) {
    // No message property is available.
  }

  final raw = error.toString().trim();

  if (raw.isEmpty) {
    return fallback;
  }

  var cleaned = raw;

  const prefixes = ['Exception: ', 'ApiException: ', 'StateError: '];

  for (final prefix in prefixes) {
    if (cleaned.startsWith(prefix)) {
      cleaned = cleaned.substring(prefix.length);
    }
  }

  if (cleaned.trim().isEmpty) {
    return fallback;
  }

  return cleaned.trim();
}
