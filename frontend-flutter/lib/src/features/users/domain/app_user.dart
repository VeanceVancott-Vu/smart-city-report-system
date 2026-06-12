import '../../auth/domain/current_user.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
  });

  final String id;
  final String fullName;
  final String email;
  final UserRole role;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      role: UserRole.fromJson(json['role'] as String),
    );
  }
}

class UserDraft {
  const UserDraft({
    required this.fullName,
    required this.email,
    required this.password,
    required this.role,
  });

  final String fullName;
  final String email;
  final String password;
  final UserRole role;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'fullName': fullName,
      'email': email,
      'password': password,
      'role': role.wireName,
    };
  }
}
