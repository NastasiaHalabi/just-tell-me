# Data Model

## Backend tables

### users
- id UUID PK
- created_at
- preferred_timezone
- preferred_locale

### integrations
- id UUID PK
- user_id FK
- provider enum
- encrypted_refresh_token
- scopes
- created_at
- revoked_at

### action_plans
- id UUID PK
- user_id FK
- original_text (optional retention policy)
- normalized_summary
- schema_version
- created_at

### action_executions
- id UUID PK
- plan_id FK
- action_id
- action_type
- policy
- status
- provider
- provider_reference nullable
- error_code nullable
- created_at
- completed_at nullable

### memories
- id UUID PK
- user_id FK
- type
- key
- encrypted_value or structured value
- created_at
- updated_at

## Mobile local database

### tasks
- id
- title
- due_at
- reminder_at
- status
- source_plan_id

### aliases
- phrase
- local_contact_identifier
- display_name
- preferred_channel

### pending_actions
- plan/action JSON
- state
- created_at

### local_history
- action summary
- state
- timestamp

## Privacy principle
Do not replicate the entire contact book or photo library to the backend.
