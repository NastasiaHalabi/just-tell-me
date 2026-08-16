# Architecture Decision Record (ADR)

## ADR-001 — Cross-platform mobile framework
**Status:** Accepted for MVP

### Decision
Use **Flutter** for the Android/iOS application.

### Rationale
- one codebase
- strong mobile UI performance
- good native bridge support for platform-specific integrations
- suitable for a microphone-first UI
- native Swift/Kotlin code can be added when a plugin does not expose required OS functionality

### Alternatives
- React Native: also viable; choose it instead if the team is much stronger in TypeScript/React.
- fully native Swift + Kotlin: maximum platform control but doubles front-end implementation effort.

---

## ADR-002 — Backend
**Status:** Accepted

### Decision
Use **FastAPI (Python)** for the backend.

### Responsibilities
- authentication/session API
- LLM orchestration
- intent/action planning
- OAuth callbacks for cloud integrations
- server-side email actions
- encrypted integration-token storage
- action audit logs
- user memory synchronization

### Non-responsibilities
Do not route actions through the backend when the phone can safely complete them locally (for example native calendar writes), unless cross-device sync is explicitly required.

---

## ADR-003 — AI returns structured plans, not free-form commands
**Status:** Accepted

### Decision
The LLM must output a versioned JSON ActionPlan validated against a schema.

It shall never directly call mobile integrations from arbitrary generated code/text.

### Rationale
This separates:
- language understanding
- policy/confirmation
- execution

and makes the system testable and safer.

---

## ADR-004 — Deterministic action executor
**Status:** Accepted

### Decision
Implement an Action Executor with explicit handlers for each supported action type.

Example:
- CalendarActionHandler
- GmailActionHandler
- WhatsAppHandoffHandler
- TelegramHandoffHandler
- PhoneActionHandler
- MediaShareHandler

The executor validates permissions and confirmation policy before execution.

---

## ADR-005 — No brittle third-party UI automation as a product dependency
**Status:** Accepted

### Decision
Do not build the core app around Accessibility Service tapping, screen scraping, simulated touches, private APIs, or other mechanisms intended to operate another app’s UI.

### Rationale
- fragile across app releases
- platform policy/review risk
- privacy/security risk
- inconsistent across iOS and Android

Use APIs, OS intents/deep links, share sheets, native frameworks, and official business APIs.

---

## ADR-006 — Local-first sensitive context
**Status:** Accepted

### Decision
Keep device contacts, selected gallery references, and native calendar data local whenever possible.

Send only the minimum normalized context required to the backend/LLM.

Example: instead of uploading the entire contact book, resolve candidate contacts locally and send only candidate display names/opaque IDs needed for disambiguation.

---

## ADR-007 — Database
**Status:** Accepted

### Decision
Use:
- PostgreSQL on backend
- local SQLite/Drift in Flutter for cached tasks, memory, pending actions, and history

Server database stores only data required for sync, cloud integrations, and account continuity.

---

## ADR-008 — Authentication
**Status:** Accepted

### Decision
Start with Sign in with Apple + Google Sign-In and optional email magic link.

Mobile API uses short-lived access tokens and refresh tokens stored securely.

---

## ADR-009 — Speech architecture
**Status:** Accepted with abstraction

### Decision
Create a `SpeechToTextProvider` interface. Do not couple the product to one speech vendor.

Pipeline:
1. capture audio
2. transcribe
3. normalize minimally
4. send text + locale/timezone context to planner

The planner, not STT, is responsible for understanding Lebanese meaning and code-switching.

---

## ADR-010 — Confirmation policy engine
**Status:** Accepted

### Decision
Use a rules-based policy engine separate from the LLM.

The LLM may recommend an action; it cannot lower the required confirmation level.

Example defaults:
- reminder create -> AUTO
- email draft -> AUTO
- email send -> CONFIRM
- delete event -> CONFIRM
- call -> CONFIRM
- external messenger personal account -> HANDOFF

---

## ADR-011 — MVP scope
**Status:** Accepted

### Include
- voice/text command
- Lebanese/Arabic/Arabizi understanding
- tasks/reminders
- native calendar
- contacts/aliases
- Gmail draft/send/search
- call handoff
- WhatsApp handoff
- Telegram handoff
- photo picker/share
- action history

### Exclude from MVP
- silently reading personal WhatsApp chats
- automatically sending from personal WhatsApp if no approved API supports it
- autonomous long-running agents
- financial transactions
- purchases
- social-media posting automation
- broad full-gallery AI indexing
- automatic response monitoring across all messengers
