import 'models.dart';

class AdminOverviewModel {
  const AdminOverviewModel({
    required this.totalUsers,
    required this.totalClassifications,
    required this.totalAdmins,
    required this.totalRegularUsers,
  });

  final int totalUsers;
  final int totalClassifications;
  final int totalAdmins;
  final int totalRegularUsers;

  factory AdminOverviewModel.fromJson(Map<String, dynamic> json) {
    return AdminOverviewModel(
      totalUsers: _parseInt(json['total_users']),
      totalClassifications: _parseInt(json['total_classifications']),
      totalAdmins: _parseInt(json['total_admins']),
      totalRegularUsers: _parseInt(
        json['total_regular_users'] ?? json['total_users_regular'],
      ),
    );
  }
}

class AdminUserModel {
  const AdminUserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.accountRole,
    this.stakeholderRole,
    this.customRole,
    this.createdAt,
  });

  final int id;
  final String fullName;
  final String email;
  final AccountRole accountRole;
  final StakeholderRole? stakeholderRole;
  final String? customRole;
  final DateTime? createdAt;

  bool get isAdmin {
    return accountRole == AccountRole.admin;
  }

  bool get isRegularUser {
    return accountRole == AccountRole.user;
  }

  String get accountRoleLabel {
    return accountRole.displayName;
  }

  String? get stakeholderDisplayName {
    if (stakeholderRole == null) {
      return null;
    }

    if (stakeholderRole == StakeholderRole.others &&
        customRole != null &&
        customRole!.trim().isNotEmpty) {
      return customRole!.trim();
    }

    return stakeholderRole!.displayName;
  }

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: _parseInt(json['id'] ?? json['user_id']),
      fullName: json['full_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      accountRole: AccountRoleExtension.fromString(
        json['account_role']?.toString() ?? json['role']?.toString(),
      ),
      stakeholderRole: StakeholderRoleExtension.fromString(
        json['stakeholder_role']?.toString(),
      ),
      customRole: json['custom_role']?.toString(),
      createdAt: _parseDateTime(json['created_at']),
    );
  }
}

class CreateAdminRequest {
  const CreateAdminRequest({
    required this.fullName,
    required this.email,
    required this.password,
  });

  final String fullName;
  final String email;
  final String password;

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName.trim(),
      'email': email.trim(),
      'password': password,

      // This request is only used by the protected
      // administrator endpoint.
      'account_role': 'ADMIN',
    };
  }
}

class AdminClassificationRecordModel {
  const AdminClassificationRecordModel({
    required this.id,
    required this.predictedGrade,
    required this.confidence,
    required this.createdAt,
    this.userId,
    this.userName,
    this.userEmail,
    this.imageUrl,
    this.modelName,
  });

  final String id;

  final int? userId;
  final String? userName;
  final String? userEmail;

  final String predictedGrade;
  final double confidence;
  final DateTime createdAt;

  final String? imageUrl;
  final String? modelName;

  double get confidencePercentage {
    return confidence * 100;
  }

  String get ownerDisplayName {
    final name = userName?.trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    final email = userEmail?.trim();

    if (email != null && email.isNotEmpty) {
      return email;
    }

    if (userId != null) {
      return 'User #$userId';
    }

    return 'Unknown user';
  }

  factory AdminClassificationRecordModel.fromJson(Map<String, dynamic> json) {
    final rawConfidence = _parseDouble(json['confidence']);

    final normalizedConfidence = rawConfidence > 1
        ? rawConfidence / 100
        : rawConfidence;

    final rawGrade =
        json['predicted_grade'] ?? json['grade'] ?? json['prediction'];

    final userData = json['user'];

    int? ownerId;
    String? ownerName;
    String? ownerEmail;

    if (userData is Map) {
      final mappedUser = Map<String, dynamic>.from(userData);

      ownerId = _parseNullableInt(mappedUser['id'] ?? mappedUser['user_id']);

      ownerName = mappedUser['full_name']?.toString();

      ownerEmail = mappedUser['email']?.toString();
    } else {
      ownerId = _parseNullableInt(json['user_id']);

      ownerName =
          json['user_name']?.toString() ?? json['full_name']?.toString();

      ownerEmail = json['user_email']?.toString() ?? json['email']?.toString();
    }

    return AdminClassificationRecordModel(
      id: (json['classification_id'] ?? json['id'] ?? '').toString(),
      userId: ownerId,
      userName: ownerName,
      userEmail: ownerEmail,
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

int? _parseNullableInt(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  return int.tryParse(value.toString());
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
