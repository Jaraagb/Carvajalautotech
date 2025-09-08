import 'package:carvajal_autotech/features/auth/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.role,
    super.firstName,
    super.lastName,
    super.avatarUrl,
    super.createdAt,
    super.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      role: _parseRole(json['role']),
      firstName: json['first_name'],
      lastName: json['last_name'],
      avatarUrl: json['avatar_url'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role.toString().split('.').last,
      'first_name': firstName,
      'last_name': lastName,
      'avatar_url': avatarUrl,
      'created_at': createdAt?.toIso8601String(),
      'is_active': isActive,
    };
  }

  static UserRole _parseRole(dynamic role) {
    if (role == null) return UserRole.student;

    switch (role.toString().toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'student':
        return UserRole.student;
      default:
        return UserRole.student;
    }
  }
}
