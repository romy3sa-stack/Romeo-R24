# Phase 2: Storage Structure

All buckets are **private**. Clients must use signed URLs.

## Buckets

| Bucket | Purpose | Max size | Allowed MIME |
|--------|---------|----------|--------------|
| `receipt-images` | Camera / gallery receipt images | 15 MB | JPEG, PNG, HEIC/HEIF, WebP |
| `receipt-pdfs` | Uploaded receipt PDFs | 25 MB | PDF |
| `verification-documents` | Accountant professional verification | 20 MB | PDF, JPEG, PNG |
| `profile-photos` | User avatars | 5 MB | JPEG, PNG, WebP |
| `support-attachments` | Support ticket files | 20 MB | PDF, images |
| `warranty-documents` | Warranty / claim evidence | 20 MB | PDF, images |

## Path convention

```
{user_id}/{yyyy}/{mm}/{uuid}-{original-filename}
```

Example:

```
a1b2c3d4-.../2026/07/9f3e...-store-receipt.jpg
```

## Security rules

- Insert/update/delete only inside own `user_id` prefix
- Admins may read for support / fraud / compliance
- Malware scanning and signed URL TTL configured before production (Phase 13 / 18)
- Never store OCR provider secrets in object metadata
