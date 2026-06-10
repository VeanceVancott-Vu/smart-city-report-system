import 'current_user.dart';

class AuthSession {
  const AuthSession({
    required this.token,
    required this.tokenType,
    required this.user,
  });

  final String token;
  final String tokenType;
  final CurrentUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: json['token'] as String,
      tokenType: json['tokenType'] as String,
      user: CurrentUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
