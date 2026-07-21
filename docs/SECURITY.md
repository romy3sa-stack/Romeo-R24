# Row-Level Security and Storage

## RLS policy summary

| Data | Consumer | Accountant / firm member | Administrator |
| --- | --- | --- | --- |
| User/profile | Own record | Approved clients | User-management access |
| Accountant profile | Own/represented firm | Own/represented firm | Manage/verify |
| Client access | View/approve/scope/revoke own invitations | Create pending invitations; view/revoke own | Manage |
| Merchant | Created or referenced by a visible receipt | Referenced by an authorised receipt | Purpose-gated if receipt-sensitive |
| Receipt/item/upload | Own | Read when active approval and scope match | Read/update only with purpose claim |
| Classification | Own | Read/write when receipt scope matches | Purpose-gated |
| Warranty/return | Own | Read when receipt scope matches | Purpose-gated |
| Categories | Read | Read | Super administrator manages |
| Notification | Own | Own | Manage |
| Subscription | Own | Represented accountant | Super administrator manages |
| Ticket | Own | Own | Super/support administrators manage |
| Audit log | Actor's rows | Actor's rows | Super/support administrators review |
| Duplicate alert | Own | Read when receipt scope matches | Purpose-gated |

Hard delete is not granted to authenticated users. Backend retention processes require the service role.

## Additional controls

- A consumer cannot change `role`, verification flags, or managed account status.
- Only a super administrator can change roles.
- Only administrators can verify accountants.
- Accountants cannot approve or broaden their own client access.
- Consumers can approve, scope, and revoke accountant access.
- Important identity, consent, receipt, classification, billing, ticket, and duplicate-alert changes are audited.
- Service-role access bypasses RLS by design and must only exist in trusted server functions.

## Storage

All buckets are private:

| Bucket | Maximum | Object path |
| --- | ---: | --- |
| `receipt-files` | 25 MiB | `<consumer_uuid>/<receipt_uuid>/<file>` |
| `verification-documents` | 15 MiB | `<accountant_user_uuid>/<file>` |
| `profile-photos` | 5 MiB | `<user_uuid>/<file>` |
| `supporting-documents` | 25 MiB | `<consumer_uuid>/<receipt_uuid>/<file>` |
| `exports` | 100 MiB | `<requesting_user_uuid>/<file>` |

Receipt files are readable by their consumer, a currently authorised accountant whose scope includes that receipt, or a purpose-gated administrator. Verification files are readable by their owner and administrators. Uploads must use the caller's UUID as the first path segment. No public buckets or public URLs are used.

Signed URLs must be short-lived and created by trusted backend functions. File extension/MIME allowlists are a first layer only; malware scanning and content verification remain deployment requirements.
