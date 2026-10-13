enum AccountRole { user, admin }

enum StakeholderRole {
  farmer,
  fiberProcessor,
  cooperative,
  buyer,
  agriculturalResearcher,
  others,
}

extension AccountRoleExtension on AccountRole {
  String get apiValue {
    switch (this) {
      case AccountRole.user:
        return 'USER';

      case AccountRole.admin:
        return 'ADMIN';
    }
  }

  String get displayName {
    switch (this) {
      case AccountRole.user:
        return 'User';

      case AccountRole.admin:
        return 'Administrator';
    }
  }

  static AccountRole fromString(String? value) {
    if (value?.toUpperCase() == 'ADMIN') {
      return AccountRole.admin;
    }

    return AccountRole.user;
  }
}

extension StakeholderRoleExtension on StakeholderRole {
  String get displayName {
    switch (this) {
      case StakeholderRole.farmer:
        return 'Farmer';

      case StakeholderRole.fiberProcessor:
        return 'Fiber Processor';

      case StakeholderRole.cooperative:
        return 'Cooperative';

      case StakeholderRole.buyer:
        return 'Buyer';

      case StakeholderRole.agriculturalResearcher:
        return 'Agricultural Researcher';

      case StakeholderRole.others:
        return 'Others';
    }
  }

  String get apiValue {
    switch (this) {
      case StakeholderRole.farmer:
        return 'FARMER';

      case StakeholderRole.fiberProcessor:
        return 'FIBER_PROCESSOR';

      case StakeholderRole.cooperative:
        return 'COOPERATIVE';

      case StakeholderRole.buyer:
        return 'BUYER';

      case StakeholderRole.agriculturalResearcher:
        return 'AGRICULTURAL_RESEARCHER';

      case StakeholderRole.others:
        return 'OTHERS';
    }
  }

  static StakeholderRole? fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'FARMER':
        return StakeholderRole.farmer;

      case 'FIBER_PROCESSOR':
        return StakeholderRole.fiberProcessor;

      case 'COOPERATIVE':
        return StakeholderRole.cooperative;

      case 'BUYER':
        return StakeholderRole.buyer;

      case 'AGRICULTURAL_RESEARCHER':
        return StakeholderRole.agriculturalResearcher;

      case 'OTHERS':
        return StakeholderRole.others;

      default:
        return null;
    }
  }
}

class UserModel {
  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.accountRole,
    this.stakeholderRole,
    this.customRole,
  });

  final int id;
  final String fullName;
  final String email;
  final AccountRole accountRole;
  final StakeholderRole? stakeholderRole;
  final String? customRole;

  bool get isAdmin {
    return accountRole == AccountRole.admin;
  }

  bool get isUser {
    return accountRole == AccountRole.user;
  }

  bool get hasCustomStakeholderRole {
    return stakeholderRole == StakeholderRole.others &&
        customRole != null &&
        customRole!.trim().isNotEmpty;
  }

  String? get stakeholderDisplayName {
    if (stakeholderRole == null) {
      return null;
    }

    if (hasCustomStakeholderRole) {
      return customRole;
    }

    return stakeholderRole!.displayName;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _parseInt(json['id']),
      fullName: json['full_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      accountRole: AccountRoleExtension.fromString(
        json['account_role']?.toString(),
      ),
      stakeholderRole: StakeholderRoleExtension.fromString(
        json['stakeholder_role']?.toString(),
      ),
      customRole: json['custom_role']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'account_role': accountRole.apiValue,
      'stakeholder_role': stakeholderRole?.apiValue,
      'custom_role': customRole,
    };
  }
}

class RegisterRequest {
  const RegisterRequest({
    required this.fullName,
    required this.email,
    required this.password,
    required this.stakeholderRole,
    this.customRole,
  });

  final String fullName;
  final String email;
  final String password;
  final StakeholderRole stakeholderRole;
  final String? customRole;

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'full_name': fullName,
      'email': email,
      'password': password,
      'stakeholder_role': stakeholderRole.apiValue,
    };

    if (stakeholderRole == StakeholderRole.others &&
        customRole != null &&
        customRole!.trim().isNotEmpty) {
      data['custom_role'] = customRole!.trim();
    }

    return data;
  }
}

class LoginRequest {
  const LoginRequest({required this.identifier, required this.password});

  final String identifier;
  final String password;

  Map<String, dynamic> toJson() {
    return {'identifier': identifier, 'password': password};
  }
}

class AuthResult {
  const AuthResult({required this.token, required this.user});

  final String token;
  final UserModel user;

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    final token =
        json['token']?.toString() ?? json['access_token']?.toString() ?? '';

    final userData = json['user'];

    if (userData is! Map<String, dynamic>) {
      throw const FormatException(
        'Authentication response does not contain user information.',
      );
    }

    return AuthResult(token: token, user: UserModel.fromJson(userData));
  }
}

/// Represents the result returned by the machine-learning
/// classification endpoint.
///
/// This does not describe an official or certified fiber grade.
/// It only stores the preliminary prediction produced by
/// ABAKASCAN.
class ClassificationResultModel {
  const ClassificationResultModel({
    required this.predictedGrade,
    required this.confidence,
    this.classificationId,
    this.createdAt,
    this.imageUrl,
    this.savedToHistory = true,
    this.modelName,
  });

  final String predictedGrade;

  /// Confidence is stored internally as a value from 0.0 to 1.0.
  final double confidence;

  final String? classificationId;
  final DateTime? createdAt;
  final String? imageUrl;
  final bool savedToHistory;
  final String? modelName;

  double get confidencePercentage {
    return confidence * 100;
  }

  factory ClassificationResultModel.fromJson(Map<String, dynamic> json) {
    final rawConfidence = _parseDouble(json['confidence']);

    final normalizedConfidence = rawConfidence > 1
        ? rawConfidence / 100
        : rawConfidence;

    final rawId = json['classification_id'] ?? json['id'];

    final rawGrade =
        json['predicted_grade'] ?? json['grade'] ?? json['prediction'];

    return ClassificationResultModel(
      classificationId: rawId?.toString(),
      predictedGrade: rawGrade?.toString() ?? '',
      confidence: normalizedConfidence.clamp(0.0, 1.0),
      createdAt: _parseDateTime(json['created_at']),
      imageUrl: json['image_url']?.toString(),
      savedToHistory: _parseBool(json['saved_to_history'], fallback: true),
      modelName: json['model_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'classification_id': classificationId,
      'predicted_grade': predictedGrade,
      'confidence': confidence,
      'created_at': createdAt?.toIso8601String(),
      'image_url': imageUrl,
      'saved_to_history': savedToHistory,
      'model_name': modelName,
    };
  }
}

/// Represents one previously saved classification shown
/// in the user's History page.
class ClassificationRecordModel {
  const ClassificationRecordModel({
    required this.id,
    required this.predictedGrade,
    required this.confidence,
    required this.createdAt,
    this.imageUrl,
    this.modelName,
  });

  final String id;
  final String predictedGrade;
  final double confidence;
  final DateTime createdAt;
  final String? imageUrl;
  final String? modelName;

  double get confidencePercentage {
    return confidence * 100;
  }

  factory ClassificationRecordModel.fromJson(Map<String, dynamic> json) {
    final rawConfidence = _parseDouble(json['confidence']);

    final normalizedConfidence = rawConfidence > 1
        ? rawConfidence / 100
        : rawConfidence;

    final rawGrade =
        json['predicted_grade'] ?? json['grade'] ?? json['prediction'];

    return ClassificationRecordModel(
      id: (json['classification_id'] ?? json['id'] ?? '').toString(),
      predictedGrade: rawGrade?.toString() ?? '',
      confidence: normalizedConfidence.clamp(0.0, 1.0),
      createdAt:
          _parseDateTime(json['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      imageUrl: json['image_url']?.toString(),
      modelName: json['model_name']?.toString(),
    );
  }
}

int _parseInt(dynamic value) {
  if (value is int) {
    return value;
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _parseDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) {
    return null;
  }

  return DateTime.tryParse(value.toString());
}

bool _parseBool(dynamic value, {required bool fallback}) {
  if (value is bool) {
    return value;
  }

  final normalized = value?.toString().toLowerCase();

  if (normalized == 'true' || normalized == '1') {
    return true;
  }

  if (normalized == 'false' || normalized == '0') {
    return false;
  }

  return fallback;
}
