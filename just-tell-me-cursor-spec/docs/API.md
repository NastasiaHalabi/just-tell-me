# Backend API Draft

## `GET /health`
Returns service health.

## `POST /v1/plan`
Creates an ActionPlan.

### Request
```json
{
  "text": "Tomorrow email Karim that the report is done",
  "client_local_datetime": "2026-08-16T22:00:00+03:00",
  "timezone": "Asia/Beirut",
  "locale_hints": ["en", "ar-LB"],
  "context": {
    "candidate_contacts": [],
    "relevant_events": []
  }
}
```

### Response
Validated ActionPlan.

## `POST /v1/integrations/google/connect`
Starts OAuth connection.

## `DELETE /v1/integrations/google`
Revokes/removes stored integration credentials.

## `POST /v1/gmail/drafts`
Creates a Gmail draft after server authorization check.

## `POST /v1/gmail/send`
Sends a validated message after mobile policy confirmation token is supplied.

### Important
A send endpoint should accept an expiring server-generated `confirmation_token` tied to:
- user
- exact action ID
- recipient
- subject/body hash

This prevents a modified client request from sending different content than the user approved.

## `GET /v1/gmail/search`
Searches authorized mailbox with constrained query parameters.

## `GET /v1/memory`
Returns synchronized non-device-secret memory.

## `PUT /v1/memory/{key}`
Updates a user-approved memory entry.

## `DELETE /v1/memory/{key}`
Deletes it.
