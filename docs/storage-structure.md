# Storage Structure

All storage buckets are **private** (not publicly accessible). Files are accessed via signed URLs with configurable expiry.

## Buckets

| Bucket | Max Size | MIME Types | Purpose |
|--------|----------|------------|---------|
| `receipt-images` | 10 MB | JPEG, PNG, HEIC, WebP | Scanned and uploaded receipt images |
| `receipt-pdfs` | 50 MB | PDF | Receipt PDF documents |
| `receipt-uploads` | 50 MB | Images + PDF | Processing queue before OCR |
| `verification-documents` | 10 MB | JPEG, PNG, PDF | Accountant professional verification |
| `profile-photos` | 5 MB | JPEG, PNG, WebP | User profile photos |
| `warranty-documents` | 10 MB | JPEG, PNG, PDF | Warranty claims and documents |
| `support-attachments` | 10 MB | JPEG, PNG, PDF | Support ticket attachments |

## Path Convention

All buckets use user-scoped paths:

```
{bucket}/{user_id}/{filename}
```

Examples:
```
receipt-images/a1b2c3d4-.../scan_20250720_143022.jpg
receipt-pdfs/a1b2c3d4-.../invoice_march.pdf
verification-documents/e5f6g7h8-.../cpa_certificate.pdf
profile-photos/a1b2c3d4-.../avatar.jpg
```

## Access Control

| Bucket | Owner | Accountant | Admin |
|--------|-------|------------|-------|
| receipt-images | Read/Write | Via signed URL (server) | Read |
| receipt-pdfs | Read/Write | Via signed URL (server) | Read |
| receipt-uploads | Read/Write | — | — |
| verification-documents | Read/Write | — | Read |
| profile-photos | Read/Write | — | — |
| warranty-documents | Read/Write | — | — |
| support-attachments | Read/Write | — | Read/Write |

## Signed URLs

Generated server-side via Edge Functions or Supabase Storage API:

```typescript
const { data } = await supabase.storage
  .from('receipt-images')
  .createSignedUrl(`${userId}/${filename}`, 3600);
```

Default expiry: 3600 seconds (1 hour), configurable via `SIGNED_URL_EXPIRY_SECONDS`.

## File Lifecycle

1. **Upload** → `receipt-uploads` bucket (processing queue)
2. **OCR processing** → Edge Function reads from uploads bucket
3. **Confirmed** → Copy to `receipt-images` or `receipt-pdfs`
4. **Database** → Store path in `receipts.receipt_image_url` or `receipts.receipt_file_url`
5. **Cleanup** → Original upload deleted after successful processing

## Security

- Malware scanning via Edge Function before processing (Phase 13)
- File type validation at upload (MIME type + extension)
- Size limits enforced at bucket level
- No public bucket access
- Accountant access requires approved client relationship + server-generated signed URL
