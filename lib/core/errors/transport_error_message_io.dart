import 'dart:io';

String? transportErrorMessage(Object error) {
  if (error is TlsException) {
    return 'Não foi possível estabelecer uma conexão segura com o servidor. Verifique o certificado, a data do aparelho e a URL do Supabase.';
  }
  if (error is SocketException) {
    return 'Não foi possível alcançar o servidor. Verifique a conexão e se a URL do Supabase está correta e acessível.';
  }
  if (error is HttpException) {
    return 'A comunicação HTTP com o servidor falhou antes de receber uma resposta completa. Tente novamente.';
  }
  return null;
}
