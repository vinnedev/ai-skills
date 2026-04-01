---
name: Token management and auto-scheduler rule
description: When approaching Claude API usage token limits, use CronCreate to schedule automatic continuation after the reset window
type: feedback
---

Monitorar o consumo de tokens durante tarefas longas. Quando estiver próximo de esgotar os tokens de uso da API Claude, usar o CronCreate para agendar a continuação automática da tarefa assim que o reset acontecer — nunca parar silenciosamente ou aguardar input do usuário.

**Why:** O usuário quer continuidade total em tarefas longas sem intervenção manual. Ao esgotar tokens, o trabalho não deve ser interrompido — deve ser retomado automaticamente após o reset.

**How to apply:**
- Durante tarefas multi-step, estimar o consumo de tokens periodicamente
- Se o saldo de tokens estiver baixo (~10-15% restante) e ainda houver tarefas pendentes no TaskList:
  1. Salvar o estado atual das tasks (TaskCreate/TaskUpdate com o que foi feito e o que falta)
  2. Usar CronCreate para agendar a continuação imediatamente após o reset (verificar quando ocorre o reset)
  3. O prompt agendado deve incluir: contexto do projeto, lista de tasks pendentes, e instrução para continuar de onde parou
- Nunca deixar tarefas em `in_progress` sem resolver — se precisar parar, marcar como `pending` com descrição do estado atual
- Ao retomar via cron, verificar TaskList primeiro para entender o que falta
