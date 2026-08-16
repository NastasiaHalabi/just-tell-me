# Requirements

## 1. Product requirements

### R1 — Natural input
The app shall accept:
- microphone input
- typed input
- English
- Arabic
- Lebanese Arabic
- Arabizi
- mixed Arabic/English/French phrases

### R2 — Multi-intent parsing
One utterance may contain multiple actions. Example:

> “Tomorrow at 9 email George, remind me to buy shampoo after work, and move my meeting with Karim to Thursday.”

The system shall parse the utterance into independent structured actions with dependencies.

### R3 — Supported action types
MVP action types:
- CREATE_REMINDER
- CREATE_TASK
- COMPLETE_TASK
- CREATE_CALENDAR_EVENT
- UPDATE_CALENDAR_EVENT
- DELETE_CALENDAR_EVENT
- QUERY_CALENDAR
- DRAFT_EMAIL
- SEND_EMAIL
- SEARCH_EMAIL
- CALL_CONTACT
- PREPARE_SMS
- PREPARE_WHATSAPP
- PREPARE_TELEGRAM
- SHARE_MEDIA
- SAVE_NOTE
- QUERY_TASKS
- QUERY_MEMORY

Later action types:
- navigation
- shopping list
- recurring routines
- file attachments
- cloud drives
- smart follow-up workflows
- business messaging integrations

### R4 — Contacts and aliases
The app shall resolve people from device contacts and app memory.

Example aliases:
- mama -> saved contact
- my boss -> saved contact
- Dr. Joe -> saved contact
- Maya piano -> saved contact/context

If multiple contacts match, the app shall ask once and remember the chosen association when the user permits it.

### R5 — Dates and relative language
The parser shall understand phrases such as:
- today / tomorrow / day after tomorrow
- هلق / اليوم / بكرا / بعد بكرا
- soboh / masa / ba3d shway
- “after work”
- “before the meeting”
- “in half an hour”
- “Thursday at 3”

Ambiguous dates shall be resolved using the user timezone and locale. If ambiguity can materially change the action, confirmation is required.

### R6 — Action confirmation levels
Every action shall have one of three policies:

**AUTO** — execute without another confirmation if previously authorized.

**CONFIRM** — show what will happen and require confirmation.

**HANDOFF** — prepare the content and transfer the user into the external app/system UI because direct execution is unavailable or inappropriate.

Default policy examples:
- create reminder: AUTO after permission
- create calendar event: AUTO or CONFIRM, user setting
- edit/delete calendar: CONFIRM by default
- draft email: AUTO
- send email: CONFIRM by default
- call: CONFIRM
- WhatsApp personal: HANDOFF by default
- gallery media share: CONFIRM/HANDOFF

### R7 — No false success
The app must only show “Sent”, “Created”, “Deleted”, etc. when the platform/API returns a success result or the OS confirms the action.

### R8 — Action history
The app shall store:
- original utterance
- parsed plan
- confirmation decision
- integration used
- action result
- timestamp
- error if any

Sensitive message bodies may be excluded or encrypted according to user settings.

### R9 — Personal memory
The app shall support lightweight user-controlled memory:
- contact aliases
- preferred communication channel
- usual session duration
- home/work labels
- common recipients
- communication tone preferences

The memory feature must be transparent, editable, and deletable.

### R10 — “What am I forgetting?”
The app shall surface unfinished, unscheduled, or overdue items. It must not invent obligations.

## 2. Integration requirements

### Calendar
Support device/native calendar first.
- iOS: EventKit
- Android: Calendar Provider / intents where appropriate
- optional cloud Google Calendar integration later

Capabilities:
- read events after permission
- create events
- edit events
- delete events with confirmation
- query schedule

### Gmail
Use OAuth and Gmail API, not UI automation.
Capabilities:
- search messages
- draft email
- send email
- reply
- attach supported files/media later

### Outlook
Phase 2 via Microsoft Graph.

### WhatsApp
Personal WhatsApp must not depend on brittle UI automation.
MVP:
- resolve recipient phone/contact
- generate message
- open supported WhatsApp URL/deep-link/share flow
- user completes send when required

WhatsApp Business Platform can be evaluated separately for business accounts and approved messaging use cases.

### Telegram
MVP:
- prepare/share to Telegram through OS handoff

Optional later:
- Telegram Bot API for bot-based experiences
- Telegram Business connected bot functionality when the user/account scenario fits

### Gallery / Photos
Use privacy-preserving system photo pickers wherever possible.
Capabilities:
- select one or more images/videos
- allow “last photo” shortcut only when platform permission/API allows reliable access
- share selected media through supported share sheet/handoff
- do not upload media to backend unless the user explicitly invokes an AI/media feature requiring it

### Phone / SMS
Use supported platform capabilities only. Avoid private APIs and accessibility-driven simulated taps for core product functionality.

## 3. Non-functional requirements

### Security
- OAuth 2.0 / PKCE where applicable
- secrets never stored in source code
- secure token storage using Keychain/Keystore
- server tokens encrypted at rest
- least-privilege scopes
- revoke integrations from Settings
- audit log for external actions

### Privacy
- request permissions only when needed
- explain why each permission is required
- minimize uploaded content
- provide Delete Account / Delete Memory / Disconnect Integration flows
- no training on private user content without explicit opt-in

### Performance
- voice-to-plan target: perceived response under 2–4 seconds on normal network conditions
- local UI interactions should feel immediate
- action execution must show progress/status

### Reliability
- idempotency keys for server-executed actions
- retry only safe/idempotent operations
- never retry SEND_EMAIL automatically after an uncertain network result without checking status
- persist action plan before execution

### Accessibility
- microphone button accessible label
- full keyboard/text input alternative
- screen reader compatible action cards
- large touch targets
- support RTL layouts

## 4. MVP acceptance scenarios

### Scenario A — Lebanese reminder
Input: “zakirne bokra 3al 5 jib l siyara mn 3end l mecanicien”
Expected: tomorrow 5:00 PM reminder with normalized task text.

### Scenario B — Multi-action
Input: “Tomorrow email Karim that the report is done and put a meeting with Maya Thursday at 2.”
Expected: email draft/send confirmation + calendar action.

### Scenario C — WhatsApp handoff
Input: “Ask Nour if she wants a session at 3.”
Expected: resolve Nour, generate appropriate message, show recipient/message, then hand off to WhatsApp supported flow.

### Scenario D — Calendar query
Input: “shu 3ande bokra?”
Expected: concise list/voice response based only on calendar/tasks the user granted access to.

### Scenario E — Ambiguous person
Two contacts named Maya.
Expected: ask user to choose; optionally remember alias/context.

### Scenario F — Permission denied
User asks to create calendar event without permission.
Expected: explain permission requirement and offer the OS permission flow; do not report success.
