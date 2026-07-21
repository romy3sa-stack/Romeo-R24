import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
              onChanged: (v) {
                if (v != null) {
                  ref.read(localeProvider.notifier).state = v;
                }
              },
            ),
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
