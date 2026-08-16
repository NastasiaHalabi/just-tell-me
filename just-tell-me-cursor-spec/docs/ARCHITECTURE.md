# Architecture

## High-level flow

```text
User voice/text
      |
      v
Mobile Input Layer
      |
      +--> Speech-to-Text Provider
      |
      v
Context Builder
(timezone, locale, selected contact candidates, minimal relevant state)
      |
      v
Backend Planner / LLM
      |
      v
Validated ActionPlan JSON
      |
      v
Mobile Policy Engine
      |
      +-------- AUTO --------> Action Executor
      |
      +------ CONFIRM -------> Preview UI -> Action Executor
      |
      +------ HANDOFF -------> External App / OS UI
                                  |
                                  v
                            Result Recorder
```

## Mobile modules

### `features/command`
- microphone UI
- text input
- plan preview
- execution progress

### `core/actions`
- models
- ActionPlan validator
- policy engine
- executor
- action registry

### `integrations/calendar`
Native calendar adapter.

### `integrations/contacts`
Local contact lookup and aliases.

### `integrations/gmail`
Calls backend Gmail integration endpoints.

### `integrations/messaging`
- WhatsApp handoff
- Telegram handoff
- SMS handoff

### `integrations/media`
Photo picker and share flow.

### `features/memory`
User-approved aliases/preferences.

### `features/history`
Action log.

## Backend modules

```text
app/
  api/
    plan.py
    auth.py
    integrations_gmail.py
    memory.py
  ai/
    planner.py
    prompts.py
    schemas.py
  integrations/
    gmail.py
  security/
    tokens.py
  db/
    models.py
    repositories.py
```

## Important design rule
The LLM is an **interpreter/planner**, not an executor.

No handler should execute raw function names supplied by the LLM. The system maps a validated enum (`SEND_EMAIL`) to a registered application handler.
