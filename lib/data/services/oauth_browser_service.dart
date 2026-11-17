import 'dart:async';

import 'package:flutter/services.dart';

abstract class OAuthBrowserService {
  // Abre a autorização no navegador e devolve o link de retorno ao app.
  Future<Uri> authenticate(Uri authorizeUri);
  Future<void> cancel();
}

class PlatformOAuthBrowserService implements OAuthBrowserService {
  const PlatformOAuthBrowserService();

  static const _channel = MethodChannel('com.example.ritmo_app/oauth');
  static const _timeout = Duration(minutes: 5);

  @override
  Future<Uri> authenticate(Uri authorizeUri) async {
    try {
      final callback = await _channel
          .invokeMethod<String>('authenticate', authorizeUri.toString())
          .timeout(_timeout);
      if (callback == null) {
        throw const FormatException('Retorno do login inválido.');
      }
      return Uri.parse(callback);
    } on TimeoutException {
      await cancel();
      rethrow;
    }
  }

  @override
  Future<void> cancel() => _channel.invokeMethod<void>('cancel');
}
