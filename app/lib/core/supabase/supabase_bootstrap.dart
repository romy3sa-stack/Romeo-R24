import 'package:supabase_flutter/supabase_flutter.dart';

import '../env/env.dart';

/// Single Supabase client bootstrap for the whole app (all three areas share
/// one project — Step 1.1). Only the public anon key is used here; every
/// privileged operation (OCR processing, email import, admin actions that
/// must bypass RLS, payment webhooks) happens server-side in Supabase Edge
/// Functions using the service_role key, which never ships in this client
/// (Rule 11, Phase 13).
class SupabaseBootstrap {
  const SupabaseBootstrap._();

  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    Env.assertConfigured();

    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    _initialized = true;
  }

  static SupabaseClient get client => Supabase.instance.client;
}
