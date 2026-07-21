# Phase 10 Testing Checklist

## In-App Notifications
- [ ] Notifications screen accessible from profile and home bell icon
- [ ] Unread badge count on home screen bell
- [ ] Notifications list shows title, message, timestamp
- [ ] Unread notifications visually distinct
- [ ] Tap notification marks as read
- [ ] Mark all as read action works
- [ ] Pull-to-refresh reloads notifications
- [ ] Empty state when no notifications

## Notification Navigation
- [ ] Receipt notifications navigate to receipt detail
- [ ] Warranty notifications navigate to warranty detail
- [ ] Return notifications navigate to return detail

## Notification Preferences
- [ ] Preferences screen accessible from profile
- [ ] Push, email, SMS toggles save to consumer_profiles
- [ ] Warranty reminder toggle saves
- [ ] Return reminder toggle saves
- [ ] Marketing toggle saves
- [ ] Success snackbar on save

## Receipt Triggers
- [ ] Saving receipt creates receipt_processed notification
- [ ] Duplicate receipt creates duplicate_detected notification
- [ ] Notifications appear in inbox after save

## Accountant Access Requests
- [ ] Pending requests shown at top of notifications screen
- [ ] Approve updates access_status to approved
- [ ] Deny updates access_status to revoked
- [ ] Success snackbars on approve/deny

## Edge Functions
- [ ] send-notification creates notifications row
- [ ] send-notification respects notification_preferences
- [ ] send-notification sends email when RESEND_API_KEY set
- [ ] send-notification logs push when FCM not configured
- [ ] process-reminders sends warranty reminders at 30/7/0 days
- [ ] process-reminders advances reminder_status
- [ ] process-reminders sends return deadline reminders

## Database
- [ ] device_tokens table migration applies
- [ ] Users can register device tokens (own RLS)
- [ ] notification_templates seeded in dev

## Accountant Portal Integration
- [ ] Inviting client triggers send-notification edge function
- [ ] Consumer sees pending request in notifications

## Security
- [ ] Users can only read/update own notifications (RLS)
- [ ] Users cannot read notification_templates
- [ ] Edge functions use service role for system inserts
