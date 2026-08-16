# Just Tell Me — Product Description

## One-line pitch
**Say what you want done. The app understands it, plans it, and completes as much as the connected services and device permissions safely allow.**

## Product vision
Just Tell Me is a cross-platform Android and iOS personal action assistant designed around natural speech instead of forms, menus, and manual app switching.

The user should be able to speak naturally in English, Arabic, Lebanese Arabic, Arabizi, or mixed Lebanese/English/French and say things such as:

- “Bokra 3al 3 ask Maya if she wants a session.”
- “ذكرني بعد الشغل جيب شامبو.”
- “Tomorrow email Karim the report and add a meeting Thursday at 2.”
- “Send the last photo I took to Nour.”
- “شو عندي بكرا؟”
- “What am I forgetting this week?”

The assistant converts the utterance into structured actions, resolves people and dates, checks permissions/integrations, previews risky actions, and executes or hands off the action.

## Core philosophy
The product is not a to-do list with voice input. It is an **action layer** over the user’s digital life.

The primary UX loop is:

1. User taps one microphone button or types.
2. App transcribes and understands the request.
3. App turns the request into one or more structured actions.
4. App resolves missing context from contacts, calendar, memory, and preferences.
5. App shows a concise plan when confirmation is required.
6. App executes supported actions.
7. App records what happened and can answer follow-up questions.

## Product promise
**Speak naturally. Consider it handled.**

The assistant must never pretend that an external action succeeded. Every action must end in one of these states:

- completed
- ready_for_confirmation
- handed_off_to_external_app
- scheduled
- failed
- unsupported

## Target users
Initial users are busy students, freelancers, tutors, creators, employees, parents, and professionals who coordinate their lives through WhatsApp, email, calendars, phone calls, and photos.

The initial regional differentiator is first-class support for Lebanese speech patterns, including Arabic/English/French code-switching and Arabizi.

## Key differentiators
- Lebanese Arabic + Arabizi + English code-switch understanding.
- Multi-action commands in one sentence.
- Real actions, not just reminders.
- Personal memory for aliases such as “mama”, “my boss”, “my student Maya”.
- Permission-aware automation.
- Confirmation policies based on risk.
- One-tap handoff to external apps when direct APIs are unavailable.
- Action history and undo where possible.

## Example experience
User says:

> “Check on Maya and ask if she wants a session tomorrow at 3. If she says yes put it on my calendar and remind me half an hour before.”

The app creates an action plan:

1. Resolve Maya from contacts/personal memory.
2. Prepare a WhatsApp message: “Hi Maya, how are you? Would you like to take a session tomorrow at 3 PM?”
3. Open the supported WhatsApp handoff flow for the user to send if direct sending is unavailable.
4. Create a follow-up intent that can later be completed manually or through a supported integration.
5. When the session is confirmed, create a 3:00 PM calendar event and a 2:30 PM reminder.

MVP note: automatic detection of Maya’s WhatsApp reply is **not** required for v1 unless an approved API/channel is available for that account type.

## Success metric
A successful product reduces a 30–90 second multi-app task to a 3–10 second spoken request plus, when required, a single confirmation.
