import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipt24_shared/receipt24_shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const ProviderScope(child: AccountantPortalApp()));
}

class AccountantPortalApp extends StatelessWidget {
  const AccountantPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '${Receipt24Strings.appName} — Accountant',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(Receipt24Colors.navy),
        ),
        useMaterial3: true,
      ),
      home: const _PlaceholderScreen(),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accountant Portal')),
      body: const Center(
        child: Text('Accountant portal — Phase 9 implementation pending'),
      ),
    );
  }
}
