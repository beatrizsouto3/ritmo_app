import '../errors/request_error.dart';

class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.publishableKey});

  const SupabaseConfig.fromEnvironment()
    : url = const String.fromEnvironment('SUPABASE_URL'),
      publishableKey = const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  final String url;
  final String publishableKey;

  Uri tableUri(String table, Map<String, String> queryParameters) {
    return _uri('/rest/v1/$table', queryParameters);
  }

  Uri authUri(String action, [Map<String, String> queryParameters = const {}]) {
    return _uri('/auth/v1/$action', queryParameters);
  }

  Uri rpcUri(String function) => _uri('/rest/v1/rpc/$function', const {});

  Uri _uri(String path, Map<String, String> queryParameters) {
    final baseUri = Uri.tryParse(url.trim());
    if (baseUri == null ||
        !baseUri.hasAuthority ||
        !['http', 'https'].contains(baseUri.scheme) ||
        publishableKey.trim().isEmpty) {
      throw SupabaseConfigurationException(
        'Configure a URL e a chave pública do Supabase.',
      );
    }
    if (publishableKey.startsWith('sb_secret_')) {
      throw SupabaseConfigurationException(
        'Use somente a chave pública do Supabase no aplicativo.',
      );
    }
    return baseUri.replace(
      path: path,
      queryParameters: queryParameters,
      fragment: '',
    );
  }
}
