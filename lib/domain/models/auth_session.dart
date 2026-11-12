class AuthSession {
  const AuthSession({
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  final String userId;
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  factory AuthSession.fromJson(Map<String, Object?> json) {
    final user = json['user'];
    final accessToken = json['access_token'];
    final refreshToken = json['refresh_token'];
    final expiresIn = json['expires_in'];
    final expiresAt = json['expires_at'];
    if (user is! Map ||
        user['id'] is! String ||
        (user['id'] as String).isEmpty ||
        accessToken is! String ||
        accessToken.isEmpty ||
        refreshToken is! String ||
        refreshToken.isEmpty ||
        (expiresAt is! num && expiresIn is! num)) {
      throw const FormatException('Resposta de autenticação inválida.');
    }
    return AuthSession(
      userId: user['id'] as String,
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt is num
          ? DateTime.fromMillisecondsSinceEpoch((expiresAt * 1000).toInt())
          : DateTime.now().add(Duration(seconds: (expiresIn as num).toInt())),
    );
  }
}
