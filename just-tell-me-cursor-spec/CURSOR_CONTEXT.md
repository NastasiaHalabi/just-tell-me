# Cursor Project Context

You are implementing **Just Tell Me**, a Flutter + FastAPI cross-platform personal action assistant.

Before making architectural changes, read:
1. DESCRIPTION.md
2. REQUIREMENTS.md
3. ADR.md
4. PLAN.md
5. docs/ARCHITECTURE.md
6. docs/ACTION_SCHEMA.md
7. docs/SECURITY_PRIVACY.md

## Non-negotiable engineering rules
- Do not invent capabilities for WhatsApp/iOS/Android.
- Never use brittle UI automation as the core implementation.
- LLM output must validate against the ActionPlan schema.
- The LLM never directly executes actions.
- The policy engine can increase required confirmation but never reduce it based on LLM output.
- Never show success before an integration confirms success.
- Keep secrets out of git.
- Prefer local processing for contacts/calendar/media.
- Write tests for every new action handler.
- Keep integrations behind interfaces/adapters.
- Finish one milestone from PLAN.md at a time.

## Coding style
- small focused files
- typed models
- dependency injection for integrations
- explicit error types
- no giant service classes
- comments explain why, not obvious syntax
- no placeholder TODOs in code claimed as complete

## When uncertain
Implement the safest supported behavior and mark unsupported capabilities clearly rather than faking completion.
