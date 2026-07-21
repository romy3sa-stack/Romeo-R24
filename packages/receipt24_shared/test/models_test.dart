import 'package:flutter_test/flutter_test.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

void main() {
  group('AuditLogModel', () {
    test('fromJson parses login audit entry', () {
      final log = AuditLogModel.fromJson({
        'id': 'log-1',
        'user_id': 'user-1',
        'action_type': 'login',
        'record_type': 'session',
        'created_at': '2025-07-20T10:00:00Z',
        'users': {'full_name': 'Jane Doe'},
      });

      expect(log.id, 'log-1');
      expect(log.actionType, 'login');
      expect(log.recordType, 'session');
      expect(log.userName, 'Jane Doe');
      expect(log.createdAt, isNotNull);
    });
  });

  group('SubscriptionPlans', () {
    test('consumer plans include free tier', () {
      expect(
        SubscriptionPlans.consumerPlans.any((p) => p.id == 'consumer_free'),
        isTrue,
      );
    });
  });
}
