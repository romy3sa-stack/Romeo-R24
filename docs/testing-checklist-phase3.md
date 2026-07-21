# Phase 3 Testing Checklist

## Welcome Screen (3.1)
- [ ] Logo and tagline display correctly
- [ ] Sign In navigates to login
- [ ] Create Account navigates to consumer registration
- [ ] Language selector changes UI text
- [ ] Privacy Policy and Terms links open legal screens
- [ ] Google/Apple buttons present (OAuth requires provider config)

## Consumer Registration (3.2)
- [ ] All required fields validated
- [ ] Email format validation works
- [ ] Password minimum 8 characters enforced
- [ ] Password confirmation match enforced
- [ ] Terms and Privacy checkboxes required
- [ ] Country, currency, language selectors work
- [ ] Successful registration redirects to email verification screen
- [ ] `users` and `consumer_profiles` rows created via trigger

## Consumer Onboarding (3.3)
- [ ] Four onboarding screens display in sequence
- [ ] Skip completes onboarding and navigates to home
- [ ] Interest selection on screen 4 saves to database
- [ ] `onboarding_completed` set to true after completion
- [ ] Returning users skip onboarding

## Accountant Registration (3.4)
- [ ] All firm fields collected
- [ ] Document upload required
- [ ] File uploaded to `verification-documents` bucket
- [ ] Account created with `pending` status
- [ ] Pending screen shown after registration
- [ ] Link to consumer registration works

## Auth Flows
- [ ] Login with valid credentials succeeds
- [ ] Login with invalid credentials shows error
- [ ] Forgot password sends reset email
- [ ] Email verification screen displays
- [ ] Resend verification works
- [ ] Sign out clears session
- [ ] Route guards redirect unauthenticated users
- [ ] Route guards redirect authenticated users away from auth screens

## Home Shell (Phase 4 start)
- [ ] Bottom navigation with 5 tabs
- [ ] Home screen shows greeting, search, action buttons
- [ ] Stats cards load from database (or show 0)
- [ ] Empty receipts state displayed
- [ ] Profile screen shows user info and language selector
- [ ] Sign out from profile works

## Multilingual (Phase 14 foundation)
- [ ] English translations complete
- [ ] French translations complete
- [ ] Portuguese, Spanish, Afrikaans, isiZulu fallback to English
- [ ] Language change persists during session

## Known Limitations
- OAuth (Google/Apple) requires Supabase provider configuration
- Receipt capture (Phase 5) not yet implemented
- Insights (Phase 7) placeholder only
- Legal content loaded from placeholder text, not database
