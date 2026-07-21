# Configuration Still Required

## Before application development

1. Create isolated Supabase projects for testing and production.
2. Populate each environment through a secret manager from the matching template.
3. Configure Auth redirect URLs, email templates, Google/Apple providers, MFA, CAPTCHA, and rate limits.
4. Implement trusted registration functions for accountant applications and administrator-issued roles.
5. Implement short-lived administrator receipt-access claims and explicit access-event logging.
6. Select and configure OCR, email, push, payment, and analytics providers.
7. Add Edge Functions for OCR, email ingestion, notifications, billing webhooks, and exports.
8. Add malware scanning and file-signature validation before processing uploads.
9. Configure backups, point-in-time recovery, monitoring, log retention, and disaster recovery.
10. Obtain legal and cybersecurity review for POPIA/GDPR, retention, privacy, and incident procedures.

## Known limitations after Phase 2

- Provider integrations and Edge Functions are intentionally not implemented.
- App/portal/dashboard UIs are intentionally not implemented.
- `access_scope` is validated defensively by deny-by-default RLS but should receive API-level JSON Schema validation.
- Currency, country, and language values use format checks; managed reference catalogues arrive in a later phase.
- File MIME allowlists do not replace malware scanning or file-signature inspection.
- Administrator purpose claims are enforced, but the privileged claim-issuing workflow remains to be built.
- Audit IP/device fields require trusted API or Edge Function population; database triggers capture actor and row changes.
- No claim of legal or cybersecurity compliance is made.
