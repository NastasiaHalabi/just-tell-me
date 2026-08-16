# Security & Privacy

## Threat model
The app may receive access to highly sensitive data: contacts, calendar entries, email, selected photos, message text, and personal memory.

## Mandatory rules
1. Least privilege OAuth scopes.
2. Keychain/Keystore for mobile secrets.
3. Encrypted refresh tokens server-side.
4. TLS only.
5. No credentials in logs.
6. No full contact-book upload by default.
7. No whole-gallery upload/indexing in MVP.
8. External sends require policy-engine authorization.
9. Confirmation screens show recipient and exact content.
10. Revoke/disconnect controls are visible in Settings.
11. Account deletion deletes stored tokens and synchronized memory.
12. Audit external side effects.

## Prompt-injection resistance
Email content and other retrieved text must be treated as untrusted data.

Never allow text inside an email, note, calendar description, or webpage to change system policy or invoke actions.

Retrieved content can provide data to the planner but cannot authorize side effects.

## Confirmation token
For server-side sends, backend should issue an expiring token for the exact content previewed to the user. The execution endpoint verifies the content hash.

## Sensitive logging
Production logs should not contain:
- raw access/refresh tokens
- message bodies by default
- full email bodies
- selected photos
- unnecessary phone numbers
