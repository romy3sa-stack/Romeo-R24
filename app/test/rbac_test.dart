import 'package:flutter_test/flutter_test.dart';
import 'package:receipt24/core/rbac/user_role.dart';
import 'package:receipt24/core/routing/app_area.dart';

void main() {
  group('UserRole', () {
    test('dbValue round-trips through fromDbValue for every role', () {
      for (final role in UserRole.values) {
        expect(UserRole.fromDbValue(role.dbValue), role);
      }
    });

    test('dbValue matches the public.user_role Postgres enum exactly', () {
      expect(UserRole.consumer.dbValue, 'consumer');
      expect(UserRole.accountant.dbValue, 'accountant');
      expect(UserRole.accountingFirmManager.dbValue, 'accounting_firm_manager');
      expect(UserRole.superAdministrator.dbValue, 'super_administrator');
      expect(UserRole.supportAdministrator.dbValue, 'support_administrator');
    });

    test('fromDbValue rejects unknown / merchant-style roles', () {
      expect(() => UserRole.fromDbValue('merchant_owner'), throwsArgumentError);
      expect(() => UserRole.fromDbValue('merchant_staff'), throwsArgumentError);
    });

    test('isAdministrator / isAccountantFamily classify roles correctly', () {
      expect(UserRole.superAdministrator.isAdministrator, isTrue);
      expect(UserRole.supportAdministrator.isAdministrator, isTrue);
      expect(UserRole.consumer.isAdministrator, isFalse);

      expect(UserRole.accountant.isAccountantFamily, isTrue);
      expect(UserRole.accountingFirmManager.isAccountantFamily, isTrue);
      expect(UserRole.consumer.isAccountantFamily, isFalse);
    });
  });

  group('AppArea.forRole', () {
    test('routes every role to exactly one area, with no merchant area', () {
      expect(AppArea.forRole(UserRole.consumer), AppArea.consumer);
      expect(AppArea.forRole(UserRole.accountant), AppArea.accountant);
      expect(AppArea.forRole(UserRole.accountingFirmManager), AppArea.accountant);
      expect(AppArea.forRole(UserRole.superAdministrator), AppArea.admin);
      expect(AppArea.forRole(UserRole.supportAdministrator), AppArea.admin);

      expect(AppArea.values, containsAll(<AppArea>[
        AppArea.consumer,
        AppArea.accountant,
        AppArea.admin,
      ]));
      expect(AppArea.values.length, 3);
    });
  });
}
