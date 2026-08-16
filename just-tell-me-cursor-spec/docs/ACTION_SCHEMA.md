# Action Schema

## Example

```json
{
  "schema_version": "1.0",
  "plan_id": "uuid",
  "original_text": "Bokra 3al 3 ask Maya if she wants a session",
  "summary": "Ask Maya whether she wants a session tomorrow at 3 PM.",
  "actions": [
    {
      "id": "a1",
      "type": "PREPARE_WHATSAPP",
      "status": "planned",
      "confirmation": "handoff",
      "recipient": {
        "contact_id": "local:123",
        "display_name": "Maya",
        "phone": "+961..."
      },
      "message": "Hi Maya, how are you? Would you like to take a session tomorrow at 3 PM?",
      "scheduled_for": null,
      "metadata": {
        "proposed_session_time": "2026-08-17T15:00:00+03:00"
      }
    }
  ],
  "needs_clarification": false,
  "clarification": null
}
```

## Required action fields
- `id`
- `type`
- `status`
- `confirmation`

## Common optional fields
- `title`
- `notes`
- `recipient`
- `message`
- `start_at`
- `end_at`
- `scheduled_for`
- `remind_at`
- `query`
- `media_refs`
- `depends_on`
- `metadata`

## Action statuses
- planned
- awaiting_confirmation
- executing
- completed
- handed_off
- scheduled
- failed
- unsupported
- cancelled

## Rule
Unknown action types must be rejected before execution.
