# Phase 12 Testing Checklist

## Authentication
- [ ] Login screen loads for unauthenticated users
- [ ] Valid admin credentials sign in successfully
- [ ] Non-admin users see wrong-role screen
- [ ] Sign out returns to login

## Dashboard
- [ ] Greeting shows admin name
- [ ] Total users, consumers, accountants counts correct
- [ ] Pending verifications count correct
- [ ] Open tickets count correct
- [ ] Total receipts count correct
- [ ] Stat cards navigate to relevant sections
- [ ] Pull-to-refresh updates stats

## User Management
- [ ] Users list shows all platform users
- [ ] Role and account status displayed
- [ ] Suspend active user sets account_status to suspended
- [ ] Activate suspended user sets account_status to active

## Accountant Verification
- [ ] Pending tab shows accountants with verification_status pending
- [ ] All tab shows all accountants
- [ ] Verify sets verification_status verified and user account_status active
- [ ] Reject sets verification_status rejected and user suspended
- [ ] Dashboard pending count updates after verify/reject

## Support Tickets
- [ ] Support tickets list loads
- [ ] Ticket details expandable
- [ ] Status update chips change ticket_status
- [ ] Empty state when no tickets

## Audit Logs (Super Admin)
- [ ] Audit logs visible to super_administrator only
- [ ] Navigation rail hides audit for support_administrator
- [ ] /audit route redirects support admins to dashboard
- [ ] Logs show action_type, record_type, user, timestamp

## Navigation
- [ ] Navigation rail: Dashboard, Users, Accountants, Support, Audit, Profile
- [ ] Shell layout with side navigation on web

## Security (RLS)
- [ ] Admin can read all users via is_admin() policy
- [ ] Super admin can update users and accountants
- [ ] Support admin can manage tickets
- [ ] Non-admin cannot access admin data

## Integration
- [ ] Accountant pending registration unblocks after admin verification
- [ ] Verified accountant can access accountant portal
