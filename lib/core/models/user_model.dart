import 'package:equatable/equatable.dart';

enum UserRole { admin, student }

class User extends Equatable {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? lastLogin;

  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.createdAt,
    this.lastLogin,
  });

  String get fullName => '$firstName $lastName';

  bool get isAdmin => role == UserRole.admin;
  bool get isStudent => role == UserRole.student;

  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    UserRole? role,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role.name,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.student,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        firstName,
        lastName,
        role,
        createdAt,
        lastLogin,
      ];
}

// Modelo para registro de estudiante
class StudentRegistration extends Equatable {
  final String email;
  final String password;
  final String firstName;
  final String lastName;

  const StudentRegistration({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'role': UserRole.student.name,
    };
  }

  @override
  List<Object> get props => [email, password, firstName, lastName];
}

// Modelo para login
class LoginCredentials extends Equatable {
  final String email;
  final String password;

  const LoginCredentials({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }

  @override
  List<Object> get props => [email, password];
}