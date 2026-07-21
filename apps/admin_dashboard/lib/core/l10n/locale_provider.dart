import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

final localeProvider = StateProvider<String>((ref) => 'en');

extension L10nContext on BuildContext {
  AppLocalizations get l10n {
    final container = ProviderScope.containerOf(this);
    return AppLocalizations(container.read(localeProvider));
  }
}
