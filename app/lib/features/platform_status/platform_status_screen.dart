import 'package:flutter/material.dart';

import '../../core/auth/app_user.dart';
import '../../core/auth/auth_service.dart';
import '../../core/env/env.dart';
import '../../core/routing/app_area.dart';
import '../../core/supabase/supabase_bootstrap.dart';
import '../../shared/widgets/receipt24_logo.dart';

/// Phase 1/2 verification screen.
///
/// This is deliberately NOT the Phase 3.1 Welcome screen (no Sign In /
/// Create Account / social buttons / language picker / legal links — those
/// belong to the next phase) and NOT a Phase 4/9/12 dashboard. Its only job
/// is to prove, at runtime, that the pieces built in this phase are wired
/// together correctly: environment config, the Supabase client, the RBAC
/// role model, and the auth-state stream.
class PlatformStatusScreen extends StatefulWidget {
  const PlatformStatusScreen({super.key});

  @override
  State<PlatformStatusScreen> createState() => _PlatformStatusScreenState();
}

class _PlatformStatusScreenState extends State<PlatformStatusScreen> {
  // AuthService touches Supabase.instance internally, so it must not be
  // constructed until Supabase.initialize() has actually completed — doing
  // so eagerly (e.g. in a field initializer evaluated during the first
  // build) throws before initState()'s async work below has a chance to run.
  AuthService? _authService;
  bool _supabaseReady = false;
  Object? _initError;

  @override
  void initState() {
    super.initState();
    _initSupabase();
  }

  Future<void> _initSupabase() async {
    try {
      await SupabaseBootstrap.ensureInitialized();
      if (mounted) {
        setState(() {
          _authService = AuthService();
          _supabaseReady = true;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _initError = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Receipt24Logo(size: 120),
                  const SizedBox(height: 16),
                  Text(
                    'Every Receipt. One Place.',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Phase 1 & 2 — Platform Foundation',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 16),
                          _StatusRow(label: 'Environment', value: Env.current.name),
                          _StatusRow(
                            label: 'Supabase client',
                            value: _initError != null
                                ? 'Error: $_initError'
                                : _supabaseReady
                                    ? 'Initialized'
                                    : 'Initializing…',
                          ),
                          _StatusRow(
                            label: 'Auth state',
                            value: _authService == null
                                ? 'Not ready'
                                : (_authService!.isSignedIn ? 'Signed in' : 'Signed out'),
                          ),
                          if (_authService?.isSignedIn ?? false)
                            _CurrentUserSection(authService: _authService!),
                          const SizedBox(height: 8),
                          Text(
                            'Consumer / Accountant / Accounting Firm Manager / Super '
                            'Administrator / Support Administrator roles are modelled in '
                            'lib/core/rbac. Registration & sign-in screens ship in Phase 3.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrentUserSection extends StatelessWidget {
  const _CurrentUserSection({required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: authService.fetchCurrentAppUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          );
        }
        final user = snapshot.data;
        if (user == null) return const SizedBox.shrink();
        final area = AppArea.forRole(user.role);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StatusRow(label: 'Role', value: user.role.dbValue),
            _StatusRow(label: 'Routed area', value: area.label),
          ],
        );
      },
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
