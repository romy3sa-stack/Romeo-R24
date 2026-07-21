import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/l10n/locale_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final auth = ref.watch(authStateProvider).valueOrNull;
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navProfile)),
      body: ListView(
        padding: const EdgeInsets.all(Receipt24Spacing.md),
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(auth?.fullName ?? ''),
            subtitle: Text(auth?.user?.email ?? ''),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            trailing: DropdownButton<String>(
              value: locale,
              underline: const SizedBox.shrink(),
              items: SupportedLanguages.languages.entries
                  .map((e) =>
                      DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) async {
                if (v == null) return;
                await ref.read(localeProvider.notifier).setLocale(v);
                final user = ref.read(currentUserProvider);
                if (user != null) {
                  await ref
                      .read(authServiceProvider)
                      .updatePreferredLanguage(user.id, v);
                }
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(l10n.themeMode),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              underline: const SizedBox.shrink(),
              items: [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text(l10n.themeSystem),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text(l10n.themeLight),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text(l10n.themeDark),
                ),
              ],
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(mode);
                }
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.security_outlined),
            title: Text(l10n.securitySettings),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/security'),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: Text(l10n.notifications),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/notifications'),
          ),
          ListTile(
            leading: const Icon(Icons.tune),
            title: Text(l10n.notificationPreferences),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/notifications/preferences'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.card_membership),
            title: Text(l10n.manageSubscription),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/subscription'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.verified_outlined),
            title: Text(l10n.warrantiesAndReturns),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/warranties'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(Receipt24Colors.error)),
            title: Text(l10n.signOut),
            onTap: () => ref.read(authServiceProvider).signOut(),
          ),
        ],
      ),
    );
  }
}
