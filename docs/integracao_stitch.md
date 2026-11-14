# Integração dos protótipos Stitch

Referências em `style/stitch_ritmo_study_platform/`. As telas são widgets Flutter,
com estado e comandos nos ViewModels e acesso ao Supabase por Repository/Service.

| Referência | Acesso no aplicativo | Situação |
|---|---|---|
| Login e cadastro | Entrada antes de autenticar | Integrado na etapa anterior; e-mail e senha |
| Dashboard / Hub | Início após autenticar | Atalhos, perfil e métricas reais de foco; sem métricas de questões ainda |
| Grade de disciplinas / edital | Disciplinas → disciplina → tópicos | Integrado; cadastro e etapas dos tópicos |
| Timer Pomodoro | Início → Foco ou cartão Pomodoro | Novo: seleção da disciplina, círculo, foco/pausas, início, pausa, cancelamento e retry ao salvar |
| Revisão SRS | Flashcards → baralho → revisar | Fluxo existente atualizado com contexto do baralho, progresso e contadores reais |
| Calibragem de matérias | Início → Encontre seu ritmo → passo 1 | Novo: objetivo, meta diária, durações e acesso ao cadastro real de disciplinas |
| Horários / notificações | Configuração → passo 2 | Novo: dias e turno persistidos; notificações ainda não implementadas |
| Diagnóstico final / boas-vindas | Configuração → passo 3 | Novo: resumo das escolhas reais |
| Transição / conclusão onboarding | Mesmo passo 3 | Variante do resumo, sem uma quarta etapa duplicada |
| Editar perfil | Ícone de pessoa no Início | Novo: nome, foco, meta, durações e rotina |
| Logo / imagem geral | Referência visual | Não representam rotas adicionais; ícone Material usado como marca provisória |

## Como preparar o banco

Aplicar `schema.sql` se for um banco novo e as migrações na ordem do README.
A nova `202611140002_study_preferences_sessions.sql` cria preferências e ciclos
com RLS. As alterações não executam SQL automaticamente no projeto remoto.

Sem essa migração, perfil e configuração mostram erro com nova tentativa;
o timer pode ser visualizado, mas uma conclusão só entra nas métricas quando
for salva no banco. A autenticação segue obrigatória, sem modo de prévia.

## Adaptações e pendências

As cores, cartões, hierarquia, seletor de modos e contador circular seguem o
Stitch. Ainda não há equivalência visual exata: Plus Jakarta Sans e a marca
final não estão empacotadas. Não são apresentados números fixos, nome de usuário
pré-definido, aprovação estimada, streak, algoritmo SM-2 não implementado ou
controles sem função de som/bloqueio de notificações.

Perfil altera preferências de estudo; trocar senha/e-mail e enviar foto exigem
fluxos próprios que não estão incluídos. Não há agendamento de sessões individuais,
notificações locais, questões/simulados ou revisão urgente por desempenho nesta
etapa. A tela de horários salva disponibilidade semanal. O módulo de métricas
mostra apenas ciclos e horas de foco persistidos.

Um ciclo incompleto não sobrevive à morte do processo do app; sair da tela pede
confirmação antes de descartá-lo. O timer continua durante bloqueio de tela e
usa tempo decorrido, não o número de ticks. A pausa não conta como estudo.
