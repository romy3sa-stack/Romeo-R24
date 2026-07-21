import 'package:flutter_test/flutter_test.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

void main() {
  group('AppLocalizations', () {
    test('English security and appearance keys resolve', () {
      final l10n = AppLocalizations('en');
      expect(l10n.securitySettings, 'Security');
      expect(l10n.themeMode, 'Theme');
      expect(l10n.retry, 'Retry');
    });

    test('French translations include phases 8–15 keys', () {
      final l10n = AppLocalizations('fr');
      expect(l10n.securitySettings, 'Sécurité');
      expect(l10n.warrantiesAndReturns, 'Garanties et retours');
      expect(l10n.manageSubscription, "Gérer l'abonnement");
      expect(l10n.adminDashboard, 'Tableau de bord admin');
    });

    test('Portuguese overrides selected keys', () {
      final l10n = AppLocalizations('pt');
      expect(l10n.securitySettings, 'Segurança');
      expect(l10n.tagline, 'Cada recibo. Um só lugar.');
    });

    test('falls back to English for unknown keys', () {
      final l10n = AppLocalizations('zu');
      expect(l10n.noReceiptsYet, 'No receipts yet');
      expect(l10n.retry, 'Zama futhi');
    });

    test('interpolates greeting params', () {
      final l10n = AppLocalizations('en');
      expect(l10n.homeGreeting('Alex'), 'Hello, Alex');
    });
  });
}
