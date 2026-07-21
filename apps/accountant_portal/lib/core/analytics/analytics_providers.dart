import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../config/env_config.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(
    apiKey: EnvConfig.posthogApiKey,
    host: EnvConfig.posthogHost,
    debug: EnvConfig.appEnv == 'development',
    appName: 'accountant',
  );
});
