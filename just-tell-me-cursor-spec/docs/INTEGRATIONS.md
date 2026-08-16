# Integration Strategy

## Native Calendar
Use official OS calendar APIs and permission flows. The app may create, retrieve, and edit calendar items only after authorization.

## Gmail
Use Gmail API with user OAuth. Support search, drafts, and send. Prefer draft-first UI during early beta.

## WhatsApp
Treat personal WhatsApp as a handoff integration unless an official approved API supports the target user/account scenario.

Do not depend on simulated taps or accessibility automation.

Track `HANDED_OFF` separately from `SENT`.

For business accounts, evaluate Meta WhatsApp Business Platform independently, including opt-in/template/messaging rules.

## Telegram
MVP uses native share/deep-link handoff where appropriate.

Future options:
- Telegram Bot API for bot conversations
- Telegram Business connected bots for business-account automation where supported

## Photos/Gallery
Use system photo picker. Request broad library access only for a clearly justified feature.

## Email/calendar future providers
Define adapters so Outlook/Microsoft Graph and Google Calendar cloud APIs can be added without changing action semantics.

```text
ActionExecutor
  EmailAdapter
    GmailAdapter
    OutlookAdapter (future)
  CalendarAdapter
    NativeCalendarAdapter
    GoogleCalendarAdapter (future)
  MessagingAdapter
    WhatsAppHandoffAdapter
    TelegramHandoffAdapter
```
