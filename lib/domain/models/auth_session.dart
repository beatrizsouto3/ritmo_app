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

  Map<String, Object?> toStoredJson() => {
    'user_id': userId,
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expires_at': expiresAt.toUtc().toIso8601String(),
    if (fullName != null) 'full_name': fullName,
    if (studyGoal != null) 'study_goal': studyGoal,
  };

  factory AuthSession.fromStoredJson(Map<String, Object?> json) {
    final userId = json['user_id'];
    final accessToken = json['access_token'];
    final refreshToken = json['refresh_token'];
    final expiresAt = json['expires_at'];
    if (userId is! String ||
        userId.isEmpty ||
        accessToken is! String ||
        accessToken.isEmpty ||
        refreshToken is! String ||
        refreshToken.isEmpty ||
        expiresAt is! String) {
      throw const FormatException('Sessão salva inválida.');
    }
    return AuthSession(
      userId: userId,
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: DateTime.parse(expiresAt),
      fullName: json['full_name'] as String?,
      studyGoal: json['study_goal'] as String?,
    );
  }

  factory AuthSession.fromJson(Map<String, Object?> json) {
    final user = json['user'];
    final accessToken = json['access_token'];
    final refreshToken = json['refresh_token'];
    final expiresIn = json['expires_in'];
    final expiresAt = json['expires_at'];
    final metadata = user is Map ? user['user_metadata'] : null;
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
      fullName: metadata is Map ? metadata['full_name'] as String? : null,
      studyGoal: metadata is Map ? metadata['study_goal'] as String? : null,
    );
  }
}
