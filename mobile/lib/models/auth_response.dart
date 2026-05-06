import 'user_model.dart';

class AuthResponse {
  final bool success;
  final String? token;
  final User? user;
  final String? message;
  final String? error;

  AuthResponse({
    required this.success,
    this.token,
    this.user,
    this.message,
    this.error,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] as bool? ?? false,
      token: json['token'] as String?,
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      message: json['message'] as String?,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'token': token,
      'user': user?.toJson(),
      'message': message,
      'error': error,
    };
  }
}
