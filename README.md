# Ritmo

Aplicativo Flutter de gestão de estudos, desenvolvido em dupla para a disciplina de Desenvolvimento para Dispositivos Móveis da UFRN.

Cadastro e login por e-mail, com cadastro e listagem de disciplinas por usuário. Arquitetura MVVM com Provider e Supabase.

## Configuração

1. Copie [config/supabase.example.json](config/supabase.example.json) para `config/supabase.json` e preencha a URL e a chave pública do projeto.
2. Em um projeto novo, execute [supabase/schema.sql](supabase/schema.sql) no SQL Editor do Supabase.
3. Habilite autenticação por e-mail e confirmação de cadastro.

## Executar

Requer Flutter com Dart 3.13 ou compatível com o `pubspec.yaml`.

Se a pasta `android/` ainda não existir:

```bash
flutter create --platforms=android --project-name ritmo_app .
```

Garanta a permissão `android.permission.INTERNET` no manifesto principal do Android.

```bash
flutter pub get
flutter run --dart-define-from-file=config/supabase.json
```

## Verificar

```bash
flutter analyze
flutter test
```
