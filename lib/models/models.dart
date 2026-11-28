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
      id: _parseInt(json['id'] ?? json['user_id']),
      fullName: json['full_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      accountRole: AccountRoleExtension.fromString(
        (json['account_role'] ?? json['role'])?.toString(),
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

class RegistrationPendingResponse {
  const RegistrationPendingResponse({
    required this.message,
    required this.email,
    required this.verificationRequired,
  });

  final String message;
  final String email;
  final bool verificationRequired;

  factory RegistrationPendingResponse.fromJson(Map<String, dynamic> json) {
    return RegistrationPendingResponse(
      message: json['message']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      verificationRequired: json['verification_required'] == true,
    );
  }
}

class VerifyEmailRequest {
  const VerifyEmailRequest({required this.email, required this.otp});

  final String email;
  final String otp;

  Map<String, dynamic> toJson() {
    return {'email': email, 'otp': otp};
  }
}

class ResendVerificationRequest {
  const ResendVerificationRequest({required this.email});

  final String email;

  Map<String, dynamic> toJson() {
    return {'email': email};
  }
}

class EmailVerificationResponse {
  const EmailVerificationResponse({
    required this.message,
    required this.email,
    required this.verified,
  });

  final String message;
  final String email;
  final bool verified;

  factory EmailVerificationResponse.fromJson(Map<String, dynamic> json) {
    return EmailVerificationResponse(
      message: json['message']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      verified: json['verified'] == true,
    );
  }
}

// ============================================================
// PASSWORD RESET
// ============================================================

class ForgotPasswordRequest {
  const ForgotPasswordRequest({required this.email});

  final String email;

  Map<String, dynamic> toJson() {
    return {'email': email};
  }
}

class ResetPasswordRequest {
  const ResetPasswordRequest({
    required this.email,
    required this.otp,
    required this.newPassword,
  });

  final String email;
  final String otp;
  final String newPassword;

  Map<String, dynamic> toJson() {
    return {'email': email, 'otp': otp, 'new_password': newPassword};
  }
}

class PasswordResetResponse {
  const PasswordResetResponse({
    required this.message,
    required this.email,
    required this.reset,
  });

  final String message;
  final String email;
  final bool reset;

  factory PasswordResetResponse.fromJson(Map<String, dynamic> json) {
    return PasswordResetResponse(
      message: json['message']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      reset: json['reset'] == true,
    );
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

// ============================================================
// CLASSIFICATION RESULT
// ============================================================

/// Stores a preliminary model prediction, not an official fiber grade.
class ClassificationResultModel {
  const ClassificationResultModel({
    required this.predictedGrade,
    required this.confidence,
    this.gradeScores,
    this.classificationId,
    this.analysisNumber,
    this.createdAt,
    this.imageUrl,
    this.savedToHistory = true,
    this.modelName,
    this.detectionStatus = 'graded',
    this.detectionMessage,
  });

  final String predictedGrade;

  /// Highest grade model score, stored from 0.0 to 1.0.
  final double confidence;

  /// Raw JK, S-I, and S-S2 scores, each from 0.0 to 1.0.
  /// Null when the complete distribution is unavailable.
  final Map<String, double>? gradeScores;

  final String? classificationId;
  final int? analysisNumber;
  final DateTime? createdAt;
  final String? imageUrl;
  final bool savedToHistory;
  final String? modelName;

  /// For non-graded outcomes, the UI must display confidence as N/A.
  final String detectionStatus;
  final String? detectionMessage;

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
      analysisNumber: _parseAnalysisNumber(json['analysis_number']),
      predictedGrade: rawGrade?.toString() ?? '',
      confidence: normalizedConfidence.clamp(0.0, 1.0).toDouble(),
      gradeScores: _parseGradeScores(json['grade_scores']),
      createdAt: _parseDateTime(json['created_at']),
      imageUrl: json['image_url']?.toString(),
      savedToHistory: _parseBool(json['saved_to_history'], fallback: true),
      modelName: json['model_name']?.toString(),
      detectionStatus: json['detection_status']?.toString() ?? 'graded',
      detectionMessage: json['detection_message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'classification_id': classificationId,
      'analysis_number': analysisNumber,
      'predicted_grade': predictedGrade,
      'confidence': confidence,
      'grade_scores': gradeScores,
      'created_at': createdAt?.toIso8601String(),
      'image_url': imageUrl,
      'saved_to_history': savedToHistory,
      'model_name': modelName,
      'detection_status': detectionStatus,
      'detection_message': detectionMessage,
    };
  }
}

// ============================================================
// CLASSIFICATION HISTORY RECORD
// ============================================================

class ClassificationRecordModel {
  const ClassificationRecordModel({
    required this.id,
    this.analysisNumber,
    required this.predictedGrade,
    required this.confidence,
    required this.createdAt,
    this.gradeScores,
    this.imageUrl,
    this.modelName,
  });

  final String id;
  final int? analysisNumber;
  final String predictedGrade;
  final double confidence;
  final DateTime createdAt;
  final Map<String, double>? gradeScores;
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
      analysisNumber: _parseAnalysisNumber(json['analysis_number']),
      predictedGrade: rawGrade?.toString() ?? '',
      confidence: normalizedConfidence.clamp(0.0, 1.0).toDouble(),
      gradeScores: _parseGradeScores(json['grade_scores']),
      createdAt:
          _parseDateTime(json['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      imageUrl: json['image_url']?.toString(),
      modelName: json['model_name']?.toString(),
    );
  }
}

// ============================================================
// PARSING HELPERS
// ============================================================

/// Reads the backend's complete 0..1 distribution without rounding,
/// rescaling, or creating values for missing grades.
Map<String, double>? _parseGradeScores(dynamic value) {
  if (value is! Map) {
    return null;
  }

  const grades = ['JK', 'S-I', 'S-S2'];

  if (value.length != grades.length) {
    return null;
  }

  final scores = <String, double>{};
  var total = 0.0;

  for (final grade in grades) {
    final rawScore = value[grade];

    final double? score = rawScore is num
        ? rawScore.toDouble()
        : rawScore is String
        ? double.tryParse(rawScore)
        : null;

    if (score == null || !score.isFinite || score < 0.0 || score > 1.0) {
      return null;
    }

    scores[grade] = score;
    total += score;
  }

  if ((total - 1.0).abs() > 0.0001) {
    return null;
  }

  return Map<String, double>.unmodifiable(scores);
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

int? _parseAnalysisNumber(dynamic value) {
  final parsed = value is int ? value : int.tryParse(value?.toString() ?? '');
  return parsed != null && parsed > 0 ? parsed : null;
}
