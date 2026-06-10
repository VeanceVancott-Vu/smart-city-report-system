enum UserRole {
  citizen('CITIZEN'),
  staff('STAFF'),
  overseer('OVERSEER');

  const UserRole(this.wireName);

  final String wireName;

  static UserRole fromJson(String value) {
    return UserRole.values.firstWhere(
      (role) => role.wireName == value,
      orElse: () => throw FormatException('Unknown user role: $value'),
    );
  }
}

class CurrentUser {
  const CurrentUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
  });

  final String id;
  final String fullName;
  final String email;
  final UserRole role;

  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    return CurrentUser(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      role: UserRole.fromJson(json['role'] as String),
    );
  }
}
