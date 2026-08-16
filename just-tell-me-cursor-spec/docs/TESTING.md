# Testing Strategy

## Unit tests
- date/time normalization
- confirmation policy
- action schema validation
- alias resolution
- state transitions
- permission handling

## Golden AI tests
Store input + expected structured result.

Do not require exact generated message wording. Assert:
- action type
- recipient
- date/time
- intent
- dependencies
- confirmation level minimum

## Integration tests
- Gmail OAuth and draft/send using test account
- calendar create/edit/delete on physical iOS and Android devices
- WhatsApp/Telegram handoff URI handling
- photo picker

## Safety tests
- LLM proposes unknown action -> rejected
- prompt injection from email -> ignored
- changed email body after confirmation -> rejected
- permission denied -> no side effect
- network timeout during send -> reconcile status before retry

## Device matrix
At minimum:
- current iOS
- one previous major iOS version
- current Android
- Android API levels matching intended Play Store support
- Samsung device if targeting Lebanon/MENA because vendor behavior can differ

## MVP release gate
- zero known P0/P1 data-loss bugs
- side-effect actions are auditable
- no unsupported action is presented as completed
- golden parser suite >= 90% action-type accuracy on curated commands
