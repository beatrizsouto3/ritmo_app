import '../../domain/models/auth_session.dart';

class AuthSessionCodec {
  const AuthSessionCodec._();

  static Map<String, Object?> toStored(AuthSession session) => {
    'user_id': session.userId,
    'access_token': session.accessToken,
    'refresh_token': session.refreshToken,
    'expires_at': session.expiresAt.toUtc().toIso8601String(),
    if (session.fullName != null) 'full_name': session.fullName,
    if (session.studyGoal != null) 'study_goal': session.studyGoal,
  };

  static AuthSession fromStored(Map<String, Object?> json) {
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

  static AuthSession fromResponse(Map<String, Object?> json) {
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
