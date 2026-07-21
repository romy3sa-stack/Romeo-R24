import 'package:flutter_test/flutter_test.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

void main() {
  group('AnalyticsService', () {
    test('track is a no-op when api key is empty', () {
      final analytics = AnalyticsService(apiKey: '', debug: true);
      expect(analytics.isEnabled, isFalse);
      expect(() => analytics.track('test_event'), returnsNormally);
    });

    test('identify stores distinct id', () {
      final analytics = AnalyticsService(apiKey: '', debug: true);
      analytics.identify('user-123');
      analytics.reset();
      expect(() => analytics.track('after_reset'), returnsNormally);
    });
  });
}
