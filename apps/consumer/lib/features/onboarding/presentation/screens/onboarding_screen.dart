import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receipt24_shared/receipt24_shared.dart';

import '../../../../core/auth/auth_providers.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../../core/widgets/receipt24_widgets.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  final _selectedInterests = <String>{};

  static const _interestLabels = {
    'personal_expenses': L10nKeys.interestPersonalExpenses,
    'business_expenses': L10nKeys.interestBusinessExpenses,
    'tax_prep': L10nKeys.interestTaxPrep,
    'warranty': L10nKeys.interestWarranty,
    'returns': L10nKeys.interestReturns,
    'accountant_sharing': L10nKeys.interestAccountant,
  };

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _complete({bool skipped = false}) async {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      await ref.read(authServiceProvider).completeOnboarding(
            userId: user.id,
            interests: skipped ? [] : _selectedInterests.toList(),
          );
    }
    if (mounted) context.go('/home');
  }

  void _next() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final pages = [
      _OnboardingPage(
        icon: Icons.wallet,
        title: l10n.onboardingTitle1,
        body: l10n.onboardingBody1,
      ),
      _OnboardingPage(
        icon: Icons.document_scanner,
        title: l10n.onboardingTitle2,
        body: l10n.onboardingBody2,
      ),
      _OnboardingPage(
        icon: Icons.verified_user,
        title: l10n.onboardingTitle3,
        body: l10n.onboardingBody3,
      ),
      _InterestPage(
        title: l10n.onboardingTitle4,
        body: l10n.onboardingBody4,
        interests: _interestLabels,
        selected: _selectedInterests,
        onToggle: (key) {
          setState(() {
            if (_selectedInterests.contains(key)) {
              _selectedInterests.remove(key);
            } else {
              _selectedInterests.add(key);
            }
          });
        },
        l10n: l10n,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _complete(skipped: true),
                child: Text(l10n.skip),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: pages,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentPage == i
                        ? const Color(Receipt24Colors.primary)
                        : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Receipt24Spacing.lg),
              child: PrimaryButton(
                label: _currentPage == 3 ? l10n.getStarted : l10n.continueButton,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Receipt24Spacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: const Color(Receipt24Colors.primary)),
          const SizedBox(height: Receipt24Spacing.xl),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Receipt24Spacing.md),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(Receipt24Colors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _InterestPage extends StatelessWidget {
  const _InterestPage({
    required this.title,
    required this.body,
    required this.interests,
    required this.selected,
    required this.onToggle,
    required this.l10n,
  });

  final String title;
  final String body;
  final Map<String, String> interests;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Receipt24Spacing.lg),
      child: Column(
        children: [
          Text(title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center),
          const SizedBox(height: Receipt24Spacing.sm),
          Text(body,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(color: Color(Receipt24Colors.textSecondary))),
          const SizedBox(height: Receipt24Spacing.lg),
          Expanded(
            child: ListView(
              children: interests.entries.map((e) {
                return CheckboxListTile(
                  value: selected.contains(e.key),
                  onChanged: (_) => onToggle(e.key),
                  title: Text(l10n.t(e.value)),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
