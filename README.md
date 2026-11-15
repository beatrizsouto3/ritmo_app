# Ritmo

Aplicativo Flutter de gestão de estudos, desenvolvido em dupla para a disciplina de Desenvolvimento para Dispositivos Móveis da UFRN.

Cadastro e login por e-mail, disciplinas e tópicos, cronograma semanal, questões,
Pomodoro e flashcards com revisão espaçada por usuário. Arquitetura MVVM com
Provider e Supabase.

No Android, a sessão é guardada com uma chave do Android Keystore e restaurada
ao abrir o app. O token é renovado quando necessário; sair da conta apaga a
sessão salva. Após instalar esta versão sobre uma anterior, entre uma vez para
criar a primeira sessão persistida.

## Configuração

1. Copie [config/supabase.example.json](config/supabase.example.json) para `config/supabase.json` e preencha a URL e a chave pública do projeto.
2. No SQL Editor de um projeto novo, execute [schema.sql](supabase/schema.sql)
   e depois as migrações, nesta ordem:
   [flashcards](supabase/migrations/202611120001_flashcards.sql),
   [tópicos](supabase/migrations/202611140001_topics.sql),
   [preferências e ciclos de foco](supabase/migrations/202611140002_study_preferences_sessions.sql)
   [cronograma, questões e edição de disciplinas](supabase/migrations/202611140003_schedule_questions_subjects.sql)
   e [revisão de tópicos](supabase/migrations/202611150001_topic_reviews.sql).
   Em um banco já configurado, execute somente as migrações ainda não aplicadas,
   preservando essa ordem. Não execute novamente o esquema inicial nesse banco.
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

## Diagnosticar erros

As telas diferenciam falhas de conexão, tempo de espera esgotado, configuração inválida, autenticação, permissões e erros retornados pelo Supabase. Falhas da API sem uma mensagem específica exibem o status HTTP e, quando disponível, o código retornado pelo servidor.

Ao executar em modo de desenvolvimento com `flutter run`, abra a aba Logging do Flutter DevTools e filtre por `ritmo.requests`. Os registros incluem o tipo da exceção e sua origem; para respostas de erro do Supabase, também incluem código, mensagem, detalhes e dica retornados pelo servidor. Cabeçalhos e corpos das requisições não são registrados. Esses registros são desabilitados nas versões de produção.

O código HTTP indica a categoria da resposta, enquanto o código do Supabase identifica a causa com mais precisão. Por exemplo, `HTTP 403; código 42501` indica falta de permissão no banco; verifique as políticas de acesso (RLS). Consulte também os logs de Auth ou Postgres no painel do Supabase para investigar falhas internas do servidor.

## Telas de estudo

Após a autenticação, o Dashboard oferece configuração inicial em três passos
(meta e matérias → dias e turno → resumo), edição de perfil de estudos,
Pomodoro, disciplinas/tópicos, cronograma semanal, questões, flashcards e
métricas de tempo e acerto. As migrações de preferências e ciclos de foco e de
cronograma e questões são necessárias para persistir esses dados.

O Pomodoro admite foco e pausas configuráveis. Pausar congela o contador;
bloquear a tela mantém o tempo ativo. Sair da tela exige confirmação e descarta
um ciclo incompleto; encerrar o processo do app também descarta esse ciclo.
Apenas um foco concluído gera registro. Falhas ao gravar oferecem nova tentativa
com o mesmo identificador para impedir registros duplicados.

Os dois resumos finais do Stitch são variantes de uma mesma etapa, implementada
como um resumo único com as escolhas atuais. Sons, bloqueio de notificações,
alertas do sistema, troca de e-mail/senha e upload de avatar não estão incluídos
nesta integração. Perfil edita nome e preferências de estudo. A rotina semanal
representa disponibilidade; as sessões individuais ficam no cronograma semanal.
As métricas usam ciclos de foco e registros de questões persistidos. A lista de
tópicos urgentes inclui tópicos sem questões, com acerto abaixo de 70%, nunca
revisados ou cuja última revisão ocorreu há mais de sete dias. A revisão é
registrada pela ação "Marcar revisão" na tela do tópico.
