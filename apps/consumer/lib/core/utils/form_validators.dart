import 'package:flutter/material.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

class FormValidators {
  static String? required(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) return l10n.fieldRequired;
    return null;
  }

  static String? email(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) return l10n.fieldRequired;
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');
    if (!regex.hasMatch(value.trim())) return l10n.invalidEmail;
    return null;
  }

  static String? password(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) return l10n.fieldRequired;
    if (value.length < 8) return l10n.passwordTooShort;
    return null;
  }

  static String? confirmPassword(
    String? value,
    String password,
    AppLocalizations l10n,
  ) {
    if (value != password) return l10n.passwordsDoNotMatch;
    return null;
  }
}
