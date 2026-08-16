# UX Specification

## Home
Keep the home screen extremely simple.

Primary elements:
- greeting/context line
- giant microphone button
- text command field
- today summary
- recent actions

## Plan preview
For a multi-action request show cards:

```text
I understood 3 things

[Calendar] Tomorrow 3:00 PM — Session with Maya
[Reminder] Tomorrow 2:30 PM — Session reminder
[Email] Karim — “The report is ready...”

                 [Do all]
```

Allow editing a card before execution.

## Confirmation copy
Bad: “Execute action?”

Good:
“Send this email to Karim?”
Show recipient + exact subject/body.

## Errors
Do not expose raw technical errors first.

Example:
“WhatsApp couldn’t be opened. Your message is still ready to copy.”

## Voice response
Voice output is optional in MVP. Visual confirmation is mandatory even if voice is enabled.

## RTL
Arabic screens must fully support right-to-left layout while preserving email addresses, times, and Latin names correctly.
