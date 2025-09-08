enum UserRole { admin, student }

class UserEntity {
  final String id;
  final String email;
  final UserRole role;
  final String? firstName;
  final String? lastName;
  final String? avatarUrl;
  final DateTime? createdAt;
  final bool isActive;

  const UserEntity({
    required this.id,
    required this.email,
    required this.role,
    this.firstName,
    this.lastName,
    this.avatarUrl,
    this.createdAt,
    this.isActive = true,
  });

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return firstName ?? lastName ?? email.split('@').first;
  }

  bool get isAdmin => role == UserRole.admin;
  bool get isStudent => role == UserRole.student;
}
