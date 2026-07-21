# Phase 4-5 Testing Checklist

## Phase 4 — Consumer Dashboard

### Home Screen
- [ ] Greeting shows user's first name
- [ ] Search bar navigates to receipts
- [ ] Scan, Upload, Add Manually buttons work
- [ ] Monthly stats load from database
- [ ] Recent receipts list shows saved receipts
- [ ] Pull-to-refresh updates stats

### Bottom Navigation
- [ ] All 5 tabs navigate correctly
- [ ] Scan tab opens capture hub

### Receipt Wallet
- [ ] Receipts list with merchant, date, amount
- [ ] Warranty and duplicate indicators show
- [ ] Sort by newest, oldest, highest, lowest amount
- [ ] Tap opens receipt detail
- [ ] Empty state with add button
- [ ] Pull-to-refresh works

### Receipt Details
- [ ] All receipt fields display
- [ ] Line items listed
- [ ] OCR confidence shown
- [ ] Duplicate warning banner
- [ ] Action chips present (share/export — Phase 6+)

## Phase 5 — Receipt Capture

### Scan Hub
- [ ] Camera capture uploads and processes
- [ ] Gallery image upload works
- [ ] PDF upload works
- [ ] Manual entry navigation
- [ ] QR scan navigation
- [ ] Email forwarding address displayed

### OCR Review
- [ ] Extracted fields shown for editing
- [ ] Low-confidence fields highlighted
- [ ] Image preview displayed
- [ ] Line items editable
- [ ] Save creates receipt in database

### Manual Entry
- [ ] All fields save correctly
- [ ] Receipt appears in wallet

### Duplicate Detection
- [ ] Matching merchant + amount flags duplicate
- [ ] Duplicate never auto-deleted

### Storage
- [ ] Images stored in receipt-images bucket
- [ ] PDFs stored in receipt-pdfs bucket
- [ ] Upload records created in receipt_uploads

## Known Limitations
- OCR uses mock data until Google Vision API configured
- QR scanner uses manual input fallback (mobile_scanner not wired)
- Email import requires inbound email Edge Function (Phase 5.4 backend)
- Expense classification not yet implemented (Phase 6)
