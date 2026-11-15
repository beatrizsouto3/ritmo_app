import 'package:flutter/services.dart';

abstract class SessionStore {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

class PlatformSessionStore implements SessionStore {
  const PlatformSessionStore();

  static const _channel = MethodChannel('com.example.ritmo_app/session');

  @override
  Future<String?> read() => _channel.invokeMethod<String>('read');

  @override
  Future<void> write(String value) =>
      _channel.invokeMethod<void>('write', value);

  @override
  Future<void> clear() => _channel.invokeMethod<void>('clear');
}
