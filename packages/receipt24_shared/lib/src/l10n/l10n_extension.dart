import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_localizations.dart';
import '../providers/app_preferences.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n {
    final container = ProviderScope.containerOf(this);
    final code = container.read(localeProvider);
    return AppLocalizations(code);
  }
}
