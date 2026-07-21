# Phase 9 Testing Checklist

## Authentication
- [ ] Login screen loads for unauthenticated users
- [ ] Valid accountant credentials sign in successfully
- [ ] Non-accountant users see wrong-role screen
- [ ] Pending accountants see verification pending screen
- [ ] Active accountants redirect to dashboard
- [ ] Sign out returns to login

## Dashboard
- [ ] Greeting shows accountant name and firm
- [ ] Total clients count is correct
- [ ] Pending invitations count is correct
- [ ] Receipts this month count reflects approved clients
- [ ] Stat cards navigate to clients list
- [ ] Pull-to-refresh updates stats

## Clients
- [ ] Clients list shows all access records
- [ ] Status chips display (approved, pending, revoked)
- [ ] Empty state with invite CTA
- [ ] Client detail shows name, email, scope, status
- [ ] Approved clients can view receipts
- [ ] Revoke access updates status

## Invite Client
- [ ] Invite by email creates pending access record
- [ ] Access scope selection (all, business, tax-related)
- [ ] Error when email has no Receipt24 account
- [ ] Invitation link displayed after success
- [ ] Copy link to clipboard works
- [ ] Duplicate invite upserts existing record

## Client Receipts
- [ ] Receipt list loads for approved client (RLS enforced)
- [ ] Receipts sorted by transaction date
- [ ] Empty state when no receipts
- [ ] Tap navigates to receipt detail

## Receipt Detail
- [ ] Merchant, date, amount displayed
- [ ] Line items listed
- [ ] Expense classification editable (category, type, mixed %)
- [ ] Classification saves with source "accountant"
- [ ] Accountant notes save to receipt

## Profile
- [ ] Name and email displayed
- [ ] Firm name, country, subscription plan shown
- [ ] Sign out works

## Security (RLS)
- [ ] Pending accountant cannot query client receipts
- [ ] Accountant only sees receipts for approved clients
- [ ] Business-only scope filters non-business receipts
- [ ] Revoked access blocks receipt queries

## Navigation
- [ ] Bottom nav: Dashboard, Clients, Profile
- [ ] Routes outside shell: invite, client detail, receipts, receipt detail
- [ ] Back navigation works correctly
