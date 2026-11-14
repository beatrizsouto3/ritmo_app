# Ritmo

Aplicativo Flutter de gestão de estudos, desenvolvido em dupla para a disciplina de Desenvolvimento para Dispositivos Móveis da UFRN.

Cadastro e login por e-mail, disciplinas e flashcards com revisão espaçada por usuário. Arquitetura MVVM com Provider e Supabase.

## Configuração

1. Copie [config/supabase.example.json](config/supabase.example.json) para `config/supabase.json` e preencha a URL e a chave pública do projeto.
2. No SQL Editor, execute [schema.sql](supabase/schema.sql) em um projeto novo e depois a [migração de flashcards](supabase/migrations/202611120001_flashcards.sql). Se disciplinas já estiverem configuradas, execute somente a migração nova.
3. Habilite autenticação por e-mail e confirmação de cadastro.

## Executar

Requer Flutter com Dart 3.13 ou compatível com o `pubspec.yaml`.

A pasta `android/` contém os fontes e a configuração nativa usados pelo Gradle para montar o APK. Esses arquivos são versionados para que a dupla compartilhe a mesma configuração, incluindo a permissão de internet necessária para acessar o Supabase. Caches, saídas de compilação, caminhos locais do SDK e chaves de assinatura ficam fora do Git.

Após clonar e configurar `config/supabase.json`, execute:

```bash
flutter pub get
flutter run --dart-define-from-file=config/supabase.json
```

## Verificar

```bash
flutter analyze
flutter test
```
