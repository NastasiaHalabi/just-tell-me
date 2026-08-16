# Implementation Plan

## Milestone 0 — Repository foundation
- Create monorepo:
  - `mobile/` Flutter
  - `backend/` FastAPI
  - `shared/` JSON schemas/examples
  - `docs/`
- Configure environments: dev/staging/prod.
- Add `.env.example` files with placeholders only.
- CI: lint + unit tests.
- Establish app IDs/package names.

**Exit condition:** blank mobile app calls `/health` on local backend.

## Milestone 1 — Command UI
Build the core single-screen experience:
- large microphone button
- text input fallback
- live transcription area
- action-plan cards
- confirm/cancel controls
- execution status
- action history screen

States:
- idle
- listening
- transcribing
- planning
- awaiting_confirmation
- executing
- completed
- partial_failure
- failed

**Exit condition:** typed fake commands can display mock ActionPlans.

## Milestone 2 — Action schema and planner
Create JSON schema for `ActionPlan`.

Implement backend `/v1/plan`:
Input:
- utterance
- timezone
- current local datetime
- locale hints
- candidate contact names if needed
- relevant calendar context only when required

Output:
- plan id
- understood summary
- actions[]
- clarification if absolutely necessary
- confidence

Add parser tests for English, Arabic, Lebanese, and Arabizi.

**Exit condition:** 50+ golden utterance tests pass schema validation.

## Milestone 3 — Local reminders/tasks
- local task database
- local notifications
- relative-time parsing verification
- recurring task foundation
- “what am I forgetting?” based on stored tasks only

**Exit condition:** voice -> parsed task -> scheduled local notification works on iOS + Android.

## Milestone 4 — Contacts and memory
- request contacts permission when user invokes a contact action
- local contact search
- disambiguation UI
- alias memory
- preferred channel memory
- memory settings/edit/delete

**Exit condition:** “call Maya” resolves an alias after first disambiguation.

## Milestone 5 — Calendar
### iOS
Implement native EventKit bridge/plugin as required.

### Android
Implement Calendar Provider access and/or suitable supported calendar flows.

Features:
- query events
- create
- edit
- delete with confirmation
- free/busy helper

**Exit condition:** “Move my meeting with Karim tomorrow from 2 to 3” works with a confirmation preview.

## Milestone 6 — Gmail
Backend:
- Google OAuth flow
- encrypted refresh token storage
- minimum Gmail scopes needed
- search
- draft
- send
- reply

Mobile:
- connect Gmail screen
- integration status
- disconnect
- send confirmation card

**Exit condition:** “Email Karim that I’m 10 minutes late” creates a preview and sends after confirmation.

## Milestone 7 — WhatsApp + Telegram handoff
Implement channel abstraction.

For each messenger:
- resolve recipient identifier/phone where possible
- generate message
- preview
- open supported external-app handoff/deep link/share flow
- record status as `HANDED_OFF`, not `SENT`, unless a supported API confirms sending

**Exit condition:** “Ask Nour if she wants a session at 3” reaches the correct supported handoff flow with the message prepared.

## Milestone 8 — Gallery / media sharing
- system photo picker
- selected asset metadata
- “share this/selected photo to X” flow
- do not upload unless needed
- support multiple selected assets later

**Exit condition:** user can select a photo and say/type “send this to Maya” -> message/share handoff.

## Milestone 9 — Speech
- implement speech provider abstraction
- microphone permissions
- audio lifecycle
- transcription
- language hints
- cancellation/retry

Test Lebanese samples with code switching.

**Exit condition:** target utterances transcribe sufficiently for planner to infer correct intent.

## Milestone 10 — Safety, permissions, reliability
- confirmation policy engine
- per-action user settings
- audit log
- idempotency
- error recovery
- token encryption
- privacy controls
- permission rationale screens

**Exit condition:** no external side-effect action bypasses the policy engine.

## Milestone 11 — Beta
- TestFlight
- Google Play internal testing
- analytics limited to product metrics
- crash reporting
- feedback action on every failed parse

Measure:
- command success rate
- correction rate
- confirmation-to-completion rate
- latency
- weekly retained users
- top unsupported commands

## Suggested build order for Cursor
Do **not** ask Cursor to generate the entire application at once.

Use this sequence:
1. repo skeleton
2. shared ActionPlan schema
3. mock planner + UI
4. real backend planner
5. tasks/reminders
6. contacts
7. calendar
8. Gmail
9. WhatsApp/Telegram handoffs
10. media picker/share
11. speech
12. hardening/tests

At the end of each phase, require tests and a runnable build before continuing.
