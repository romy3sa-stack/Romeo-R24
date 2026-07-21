# Phase 1–2 Testing Checklist

## Automated foundation tests

- [ ] All migrations apply to a clean PostgreSQL/Supabase instance.
- [ ] Database lint reports no errors.
- [ ] All required tables, foreign keys, enum roles, and indexes exist.
- [ ] RLS is enabled and forced on every public application table.
- [ ] All five storage buckets exist and remain private.
- [ ] Receipt and consent changes create audit rows.

## Authorization tests

- [ ] A consumer can read and update their own receipt.
- [ ] A consumer cannot read or mutate another consumer's receipt.
- [ ] A consumer cannot escalate their role.
- [ ] Authenticated users cannot hard-delete financial records.
- [ ] An accountant cannot read a client before approval.
- [ ] An approved accountant can read only receipts allowed by the approved scope.
- [ ] Revocation removes accountant access immediately.
- [ ] A firm member cannot represent an unrelated accountant.
- [ ] An accountant cannot approve or broaden their own invitation.
- [ ] An administrator without a trusted purpose claim cannot read receipts.
- [ ] An administrator with a valid short-lived purpose claim can perform the required investigation.
- [ ] Anonymous users cannot access public application tables or private objects.

## Storage tests

- [ ] Upload paths outside the caller's UUID folder are rejected.
- [ ] Unsupported MIME types and oversized files are rejected.
- [ ] A consumer can read their own receipt object.
- [ ] An approved accountant can read an in-scope receipt object.
- [ ] A revoked accountant cannot read an object or reuse an expired signed URL.
- [ ] Verification documents remain private.
- [ ] Uploaded files pass malware/content scanning before processing.

## Deployment gates

- [ ] Development, testing, and production use separate projects and credentials.
- [ ] Secrets are configured only in server/secret-manager environments.
- [ ] Backups, point-in-time recovery, monitoring, rate limiting, and incident alerts are configured.
- [ ] Administrator purpose claims are short-lived and auditable.
- [ ] Privacy/retention workflows receive legal and cybersecurity review.
