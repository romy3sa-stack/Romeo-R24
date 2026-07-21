import 'package:flutter/material.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../../core/l10n/locale_provider.dart';

class LegalContentScreen extends StatelessWidget {
  const LegalContentScreen({super.key, required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isPrivacy = type == 'privacy';

    return Scaffold(
      appBar: AppBar(
        title: Text(isPrivacy ? l10n.privacyPolicy : l10n.termsAndConditions),
      ),
      body: const Padding(
        padding: EdgeInsets.all(Receipt24Spacing.lg),
        child: SingleChildScrollView(
          child: Text(
            'Legal content will be loaded from the database in production. '
            'This placeholder is shown during development.\n\n'
            'Receipt24 is designed around POPIA and GDPR principles. '
            'Do not claim legal compliance until reviewed by qualified '
            'legal and cybersecurity professionals.',
          ),
        ),
      ),
    );
  }
}
