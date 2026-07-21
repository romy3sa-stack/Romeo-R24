/// Compile-time environment configuration.
///
/// Values are injected at build/run time via `--dart-define-from-file`, e.g.:
///
///   flutter run --dart-define-from-file=env/development.json
///
/// No `.env` file is ever bundled as an asset and no secret key is ever
/// referenced here (Rule 11). Only the Supabase **anon** key is read — it is
/// designed by Supabase to be public and is safe to ship in a client binary
/// because every table is protected by Row Level Security (see
/// supabase/migrations/20260101000011_row_level_security.sql). The
/// `service_role` key must NEVER appear in this app.
///
/// See docs/ENVIRONMENTS.md for the full list of environments and how each
/// one supplies these values in CI/CD.
library;

enum AppEnvironment { development, test, production }

class Env {
  const Env._();

  static const String _envName = String.fromEnvironment(
    'APP_ENVIRONMENT',
    defaultValue: 'development',
  );

  static AppEnvironment get current => switch (_envName) {
        'production' => AppEnvironment.production,
        'test' => AppEnvironment.test,
        _ => AppEnvironment.development,
      };

  /// Public Supabase project URL, e.g. https://xxxxx.supabase.co
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://localhost:54321',
  );

  /// Public (anon) Supabase key. Never the service_role key.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Public analytics write key (PostHog/Firebase). Safe for client use.
  static const String analyticsKey = String.fromEnvironment(
    'ANALYTICS_KEY',
    defaultValue: '',
  );

  /// Publishable (public) payment key, e.g. Stripe publishable key.
  /// The corresponding secret key lives only in Supabase Edge Function
  /// secrets, never here.
  static const String paymentsPublishableKey = String.fromEnvironment(
    'PAYMENTS_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  static bool get isProduction => current == AppEnvironment.production;

  static void assertConfigured() {
    assert(
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty,
      'Missing SUPABASE_URL / SUPABASE_ANON_KEY. Run with '
      '--dart-define-from-file=env/<environment>.json (see docs/ENVIRONMENTS.md).',
    );
  }
}
