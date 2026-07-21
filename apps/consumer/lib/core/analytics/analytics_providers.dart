import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import 'env_config.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(
    apiKey: EnvConfig.posthogApiKey,
    host: EnvConfig.posthogHost,
    debug: EnvConfig.isDevelopment,
    appName: 'consumer',
  );
});
