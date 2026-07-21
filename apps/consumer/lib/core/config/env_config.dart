import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration — secrets loaded from .env, never hard-coded.
abstract final class EnvConfig {
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? 'http://127.0.0.1:54321';

  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static String get appEnv => dotenv.env['APP_ENV'] ?? 'development';

  static String get posthogApiKey => dotenv.env['POSTHOG_API_KEY'] ?? '';

  static String get posthogHost =>
      dotenv.env['POSTHOG_HOST'] ?? 'https://app.posthog.com';

  static bool get isDevelopment => appEnv == 'development';
  static bool get isProduction => appEnv == 'production';
}
