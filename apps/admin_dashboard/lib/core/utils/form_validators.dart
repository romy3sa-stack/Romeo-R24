import 'package:receipt24_shared/receipt24_shared.dart';

abstract final class FormValidators {
  static String? email(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) return l10n.fieldRequired;
    if (!value.contains('@')) return l10n.invalidEmail;
    return null;
  }

  static String? password(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) return l10n.fieldRequired;
    if (value.length < 8) return l10n.passwordTooShort;
    return null;
  }
}
