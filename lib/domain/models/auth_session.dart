class AuthSession {
  const AuthSession({
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    this.fullName,
    this.studyGoal,
  });

  final String userId;
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final String? fullName;
  final String? studyGoal;
}
