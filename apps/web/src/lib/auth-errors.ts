/** Maps Supabase Auth errors to user-friendly messages. */
export function mapAuthError(message: string, code?: string): string {
  const normalized = (code ?? message).toLowerCase();

  if (normalized.includes('email_not_confirmed') || message.includes('Email not confirmed')) {
    return 'Please confirm your email before signing in. Check your inbox, or ask an admin to auto-confirm your account in Supabase.';
  }
  if (normalized.includes('invalid_credentials') || normalized.includes('invalid login')) {
    return 'Invalid email or password. Please try again.';
  }
  if (normalized.includes('email_address_invalid')) {
    return 'Please enter a valid email address.';
  }
  return message || 'Sign in failed. Please try again.';
}
