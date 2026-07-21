# Phase 8 Testing Checklist

## Warranties Hub
- [ ] Warranties & returns accessible from profile screen
- [ ] Tabbed hub shows warranties and returns lists
- [ ] Empty states for no warranties / no returns
- [ ] Pull-to-refresh reloads both tabs
- [ ] Status chips display on list items
- [ ] Expiring/expired warranties show correct icons and colours

## Add Warranty
- [ ] Add warranty from receipt detail screen
- [ ] Product selection when receipt has line items
- [ ] Warranty start date picker works
- [ ] Warranty period slider (30–1095 days)
- [ ] Merchant contact and notes fields save
- [ ] Reminder toggle saves correct reminder_status
- [ ] Receipt warranty_available flag set on create
- [ ] Success snackbar and navigation back

## Warranty Detail
- [ ] Expiring soon banner when within 30 days
- [ ] All warranty fields displayed
- [ ] Status update chips change warranty_status
- [ ] Claim reference prompted when starting claim
- [ ] Reminder toggle enables/disables reminders

## Add Return
- [ ] Record return from receipt detail screen
- [ ] Request type selection (return, refund, exchange)
- [ ] Return reason and description save
- [ ] Return deadline date picker works
- [ ] Optional refund amount saves
- [ ] Receipt return_deadline updated when set
- [ ] Success snackbar and navigation back

## Return Detail
- [ ] Deadline soon banner when within 7 days
- [ ] All return fields displayed
- [ ] Status update chips change request_status
- [ ] Refund amount prompted when marking refund received

## Home Integration
- [ ] Active warranties count reflects non-expired active warranties
- [ ] Return deadlines count reflects upcoming 30-day deadlines
- [ ] Tapping warranty/return stat cards opens hub
- [ ] Pull-to-refresh updates stats

## Navigation
- [ ] Routes: /warranties, /warranties/:id, /warranties/add/:receiptId
- [ ] Routes: /returns/:id, /returns/add/:receiptId
- [ ] Deep links from hub list items work
