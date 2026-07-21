import 'l10n_keys.dart';

/// Provides translated strings for a given locale code.
class AppLocalizations {
  AppLocalizations(this.localeCode);

  final String localeCode;

  static const supportedLocales = ['en', 'fr', 'pt', 'es', 'af', 'zu'];

  String t(String key, {Map<String, String>? params}) {
    final text = _translations[localeCode]?[key] ??
        _translations['en']![key] ??
        key;
    if (params == null) return text;
    var result = text;
    for (final entry in params.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value);
    }
    return result;
  }

  String get appName => t(L10nKeys.appName);
  String get tagline => t(L10nKeys.tagline);
  String get signIn => t(L10nKeys.signIn);
  String get createAccount => t(L10nKeys.createAccount);
  String get continueWithGoogle => t(L10nKeys.continueWithGoogle);
  String get continueWithApple => t(L10nKeys.continueWithApple);
  String get privacyPolicy => t(L10nKeys.privacyPolicy);
  String get termsAndConditions => t(L10nKeys.termsAndConditions);
  String get language => t(L10nKeys.language);
  String get email => t(L10nKeys.email);
  String get password => t(L10nKeys.password);
  String get confirmPassword => t(L10nKeys.confirmPassword);
  String get fullName => t(L10nKeys.fullName);
  String get mobileNumber => t(L10nKeys.mobileNumber);
  String get country => t(L10nKeys.country);
  String get currency => t(L10nKeys.currency);
  String get preferredLanguage => t(L10nKeys.preferredLanguage);
  String get acceptTerms => t(L10nKeys.acceptTerms);
  String get acceptPrivacy => t(L10nKeys.acceptPrivacy);
  String get register => t(L10nKeys.register);
  String get login => t(L10nKeys.login);
  String get forgotPassword => t(L10nKeys.forgotPassword);
  String get resetPassword => t(L10nKeys.resetPassword);
  String get sendResetLink => t(L10nKeys.sendResetLink);
  String get backToLogin => t(L10nKeys.backToLogin);
  String get alreadyHaveAccount => t(L10nKeys.alreadyHaveAccount);
  String get dontHaveAccount => t(L10nKeys.dontHaveAccount);
  String get verifyEmailTitle => t(L10nKeys.verifyEmailTitle);
  String get verifyEmailMessage => t(L10nKeys.verifyEmailMessage);
  String get resendVerification => t(L10nKeys.resendVerification);
  String get continueButton => t(L10nKeys.continueButton);
  String get skip => t(L10nKeys.skip);
  String get getStarted => t(L10nKeys.getStarted);
  String get onboardingTitle1 => t(L10nKeys.onboardingTitle1);
  String get onboardingBody1 => t(L10nKeys.onboardingBody1);
  String get onboardingTitle2 => t(L10nKeys.onboardingTitle2);
  String get onboardingBody2 => t(L10nKeys.onboardingBody2);
  String get onboardingTitle3 => t(L10nKeys.onboardingTitle3);
  String get onboardingBody3 => t(L10nKeys.onboardingBody3);
  String get onboardingTitle4 => t(L10nKeys.onboardingTitle4);
  String get onboardingBody4 => t(L10nKeys.onboardingBody4);
  String get interestPersonalExpenses => t(L10nKeys.interestPersonalExpenses);
  String get interestBusinessExpenses => t(L10nKeys.interestBusinessExpenses);
  String get interestTaxPrep => t(L10nKeys.interestTaxPrep);
  String get interestWarranty => t(L10nKeys.interestWarranty);
  String get interestReturns => t(L10nKeys.interestReturns);
  String get interestAccountant => t(L10nKeys.interestAccountant);
  String get registerAsAccountant => t(L10nKeys.registerAsAccountant);
  String get registerAsConsumer => t(L10nKeys.registerAsConsumer);
  String get firmName => t(L10nKeys.firmName);
  String get professionalRegNumber => t(L10nKeys.professionalRegNumber);
  String get taxNumber => t(L10nKeys.taxNumber);
  String get address => t(L10nKeys.address);
  String get verificationDocument => t(L10nKeys.verificationDocument);
  String get uploadDocument => t(L10nKeys.uploadDocument);
  String get subscriptionPlan => t(L10nKeys.subscriptionPlan);
  String get planSolo => t(L10nKeys.planSolo);
  String get planProfessional => t(L10nKeys.planProfessional);
  String get planEnterprise => t(L10nKeys.planEnterprise);
  String get accountantPendingTitle => t(L10nKeys.accountantPendingTitle);
  String get accountantPendingMessage => t(L10nKeys.accountantPendingMessage);
  String get signOut => t(L10nKeys.signOut);
  String homeGreeting(String name) =>
      t(L10nKeys.homeGreeting, params: {'name': name});
  String get searchReceipts => t(L10nKeys.searchReceipts);
  String get scanReceipt => t(L10nKeys.scanReceipt);
  String get uploadReceipt => t(L10nKeys.uploadReceipt);
  String get addManually => t(L10nKeys.addManually);
  String get totalSpendingMonth => t(L10nKeys.totalSpendingMonth);
  String get receiptsThisMonth => t(L10nKeys.receiptsThisMonth);
  String get activeWarranties => t(L10nKeys.activeWarranties);
  String get returnDeadlines => t(L10nKeys.returnDeadlines);
  String get recentReceipts => t(L10nKeys.recentReceipts);
  String get noReceiptsYet => t(L10nKeys.noReceiptsYet);
  String get noReceiptsHint => t(L10nKeys.noReceiptsHint);
  String get navHome => t(L10nKeys.navHome);
  String get navReceipts => t(L10nKeys.navReceipts);
  String get navScan => t(L10nKeys.navScan);
  String get navInsights => t(L10nKeys.navInsights);
  String get navProfile => t(L10nKeys.navProfile);
  String get fieldRequired => t(L10nKeys.fieldRequired);
  String get invalidEmail => t(L10nKeys.invalidEmail);
  String get passwordTooShort => t(L10nKeys.passwordTooShort);
  String get passwordsDoNotMatch => t(L10nKeys.passwordsDoNotMatch);
  String get mustAcceptTerms => t(L10nKeys.mustAcceptTerms);
  String get mustAcceptPrivacy => t(L10nKeys.mustAcceptPrivacy);
  String get registrationSuccess => t(L10nKeys.registrationSuccess);
  String get loginFailed => t(L10nKeys.loginFailed);
  String get genericError => t(L10nKeys.genericError);
  String get captureTitle => t(L10nKeys.captureTitle);
  String get captureCamera => t(L10nKeys.captureCamera);
  String get captureGallery => t(L10nKeys.captureGallery);
  String get capturePdf => t(L10nKeys.capturePdf);
  String get captureManual => t(L10nKeys.captureManual);
  String get captureQr => t(L10nKeys.captureQr);
  String get captureEmail => t(L10nKeys.captureEmail);
  String get emailForwardingHint => t(L10nKeys.emailForwardingHint);
  String get reviewTitle => t(L10nKeys.reviewTitle);
  String get reviewSubtitle => t(L10nKeys.reviewSubtitle);
  String get saveReceipt => t(L10nKeys.saveReceipt);
  String get merchantName => t(L10nKeys.merchantName);
  String get transactionDate => t(L10nKeys.transactionDate);
  String get totalAmount => t(L10nKeys.totalAmount);
  String get taxAmount => t(L10nKeys.taxAmount);
  String get receiptNumber => t(L10nKeys.receiptNumber);
  String get paymentMethodLabel => t(L10nKeys.paymentMethodLabel);
  String get itemsPurchased => t(L10nKeys.itemsPurchased);
  String get lowConfidence => t(L10nKeys.lowConfidence);
  String get processingReceipt => t(L10nKeys.processingReceipt);
  String get receiptSaved => t(L10nKeys.receiptSaved);
  String get filterSort => t(L10nKeys.filterSort);
  String get sortNewest => t(L10nKeys.sortNewest);
  String get sortOldest => t(L10nKeys.sortOldest);
  String get sortHighest => t(L10nKeys.sortHighest);
  String get sortLowest => t(L10nKeys.sortLowest);
  String get duplicateWarning => t(L10nKeys.duplicateWarning);
  String get receiptDetails => t(L10nKeys.receiptDetails);
  String get ocrConfidence => t(L10nKeys.ocrConfidence);
  String get addItem => t(L10nKeys.addItem);
  String get removeItem => t(L10nKeys.removeItem);
  String get qrScanTitle => t(L10nKeys.qrScanTitle);
  String get qrScanHint => t(L10nKeys.qrScanHint);
  String get qrResult => t(L10nKeys.qrResult);

  static final Map<String, Map<String, String>> _translations = {
    'en': _en,
    'fr': _fr,
    'pt': _pt,
    'es': _es,
    'af': _af,
    'zu': _zu,
  };
}

const _en = {
  'appName': 'Receipt24',
  'tagline': 'Every Receipt. One Place.',
  'signIn': 'Sign In',
  'createAccount': 'Create Account',
  'continueWithGoogle': 'Continue with Google',
  'continueWithApple': 'Continue with Apple',
  'privacyPolicy': 'Privacy Policy',
  'termsAndConditions': 'Terms and Conditions',
  'language': 'Language',
  'email': 'Email address',
  'password': 'Password',
  'confirmPassword': 'Confirm password',
  'fullName': 'Full name',
  'mobileNumber': 'Mobile number',
  'country': 'Country',
  'currency': 'Preferred currency',
  'preferredLanguage': 'Preferred language',
  'acceptTerms': 'I accept the Terms and Conditions',
  'acceptPrivacy': 'I accept the Privacy Policy',
  'register': 'Register',
  'login': 'Log in',
  'forgotPassword': 'Forgot password?',
  'resetPassword': 'Reset password',
  'sendResetLink': 'Send reset link',
  'backToLogin': 'Back to login',
  'alreadyHaveAccount': 'Already have an account?',
  'dontHaveAccount': "Don't have an account?",
  'verifyEmailTitle': 'Verify your email',
  'verifyEmailMessage':
      'We sent a verification link to your email. Please check your inbox and click the link to activate your account.',
  'resendVerification': 'Resend verification email',
  'continueButton': 'Continue',
  'skip': 'Skip',
  'getStarted': 'Get started',
  'onboardingTitle1': 'All your receipts in one place',
  'onboardingBody1':
      'Keep every receipt organised in a secure digital wallet. No more lost paper slips.',
  'onboardingTitle2': 'Scan or upload receipts',
  'onboardingBody2':
      'Photograph paper receipts, upload images or PDFs, or forward email receipts automatically.',
  'onboardingTitle3': 'Track warranties and expenses',
  'onboardingBody3':
      'Monitor warranties, return deadlines, tax-related expenses, and business spending with ease.',
  'onboardingTitle4': 'What interests you?',
  'onboardingBody4':
      "Select the features you'd like to focus on. You can change these later.",
  'interestPersonalExpenses': 'Personal expense tracking',
  'interestBusinessExpenses': 'Business expenses',
  'interestTaxPrep': 'Tax preparation',
  'interestWarranty': 'Warranty tracking',
  'interestReturns': 'Returns and refunds',
  'interestAccountant': 'Accountant sharing',
  'registerAsAccountant': 'Register as accountant',
  'registerAsConsumer': 'Register as consumer',
  'firmName': 'Firm name',
  'professionalRegNumber': 'Professional registration number',
  'taxNumber': 'Tax number',
  'address': 'Address',
  'verificationDocument': 'Professional verification document',
  'uploadDocument': 'Upload document',
  'subscriptionPlan': 'Preferred subscription plan',
  'planSolo': 'Solo Accountant',
  'planProfessional': 'Professional Firm',
  'planEnterprise': 'Enterprise Firm',
  'accountantPendingTitle': 'Application under review',
  'accountantPendingMessage':
      'Your accountant account is pending verification. An administrator will review your documents and approve your account shortly.',
  'signOut': 'Sign out',
  'homeGreeting': 'Hello, {name}',
  'searchReceipts': 'Search receipts',
  'scanReceipt': 'Scan Receipt',
  'uploadReceipt': 'Upload Receipt',
  'addManually': 'Add Manually',
  'totalSpendingMonth': 'Spending this month',
  'receiptsThisMonth': 'Receipts this month',
  'activeWarranties': 'Active warranties',
  'returnDeadlines': 'Return deadlines',
  'recentReceipts': 'Recent receipts',
  'noReceiptsYet': 'No receipts yet',
  'noReceiptsHint': 'Scan or upload your first receipt to get started.',
  'navHome': 'Home',
  'navReceipts': 'Receipts',
  'navScan': 'Scan',
  'navInsights': 'Insights',
  'navProfile': 'Profile',
  'fieldRequired': 'This field is required',
  'invalidEmail': 'Please enter a valid email address',
  'passwordTooShort': 'Password must be at least 8 characters',
  'passwordsDoNotMatch': 'Passwords do not match',
  'mustAcceptTerms': 'You must accept the Terms and Conditions',
  'mustAcceptPrivacy': 'You must accept the Privacy Policy',
  'registrationSuccess': 'Account created successfully',
  'loginFailed': 'Login failed. Please check your credentials.',
  'genericError': 'Something went wrong. Please try again.',
  'captureTitle': 'Add a receipt',
  'captureCamera': 'Take photo',
  'captureGallery': 'Upload image',
  'capturePdf': 'Upload PDF',
  'captureManual': 'Enter manually',
  'captureQr': 'Scan QR code',
  'captureEmail': 'Email import',
  'emailForwardingHint': 'Forward receipts to your unique address:',
  'reviewTitle': 'Review receipt',
  'reviewSubtitle': 'Check and correct the extracted details before saving.',
  'saveReceipt': 'Save receipt',
  'merchantName': 'Merchant name',
  'transactionDate': 'Transaction date',
  'totalAmount': 'Total amount',
  'taxAmount': 'Tax amount',
  'receiptNumber': 'Receipt number',
  'paymentMethodLabel': 'Payment method',
  'itemsPurchased': 'Items purchased',
  'lowConfidence': 'Low confidence — please verify',
  'processingReceipt': 'Processing receipt...',
  'receiptSaved': 'Receipt saved successfully',
  'filterSort': 'Filter & sort',
  'sortNewest': 'Newest first',
  'sortOldest': 'Oldest first',
  'sortHighest': 'Highest amount',
  'sortLowest': 'Lowest amount',
  'duplicateWarning': 'Possible duplicate detected',
  'receiptDetails': 'Receipt details',
  'ocrConfidence': 'OCR confidence',
  'addItem': 'Add item',
  'removeItem': 'Remove',
  'qrScanTitle': 'Scan QR code',
  'qrScanHint': 'Point your camera at a QR code on the receipt',
  'qrResult': 'QR code detected',
};

const _fr = {
  'appName': 'Receipt24',
  'tagline': 'Chaque reçu. Un seul endroit.',
  'signIn': 'Se connecter',
  'createAccount': 'Créer un compte',
  'continueWithGoogle': 'Continuer avec Google',
  'continueWithApple': 'Continuer avec Apple',
  'privacyPolicy': 'Politique de confidentialité',
  'termsAndConditions': 'Conditions générales',
  'language': 'Langue',
  'email': 'Adresse e-mail',
  'password': 'Mot de passe',
  'confirmPassword': 'Confirmer le mot de passe',
  'fullName': 'Nom complet',
  'mobileNumber': 'Numéro de mobile',
  'country': 'Pays',
  'currency': 'Devise préférée',
  'preferredLanguage': 'Langue préférée',
  'acceptTerms': "J'accepte les Conditions générales",
  'acceptPrivacy': "J'accepte la Politique de confidentialité",
  'register': "S'inscrire",
  'login': 'Connexion',
  'forgotPassword': 'Mot de passe oublié ?',
  'resetPassword': 'Réinitialiser le mot de passe',
  'sendResetLink': 'Envoyer le lien',
  'backToLogin': 'Retour à la connexion',
  'alreadyHaveAccount': 'Vous avez déjà un compte ?',
  'dontHaveAccount': "Vous n'avez pas de compte ?",
  'verifyEmailTitle': 'Vérifiez votre e-mail',
  'verifyEmailMessage':
      'Nous avons envoyé un lien de vérification à votre e-mail.',
  'resendVerification': "Renvoyer l'e-mail de vérification",
  'continueButton': 'Continuer',
  'skip': 'Passer',
  'getStarted': 'Commencer',
  'onboardingTitle1': 'Tous vos reçus en un seul endroit',
  'onboardingBody1':
      'Gardez chaque reçu organisé dans un portefeuille numérique sécurisé.',
  'onboardingTitle2': 'Scannez ou téléchargez des reçus',
  'onboardingBody2':
      'Photographiez des reçus papier, téléchargez des images ou des PDF.',
  'onboardingTitle3': 'Suivez les garanties et dépenses',
  'onboardingBody3':
      'Surveillez les garanties, les délais de retour et les dépenses.',
  'onboardingTitle4': "Qu'est-ce qui vous intéresse ?",
  'onboardingBody4': 'Sélectionnez les fonctionnalités qui vous intéressent.',
  'interestPersonalExpenses': 'Suivi des dépenses personnelles',
  'interestBusinessExpenses': 'Dépenses professionnelles',
  'interestTaxPrep': 'Préparation fiscale',
  'interestWarranty': 'Suivi des garanties',
  'interestReturns': 'Retours et remboursements',
  'interestAccountant': 'Partage avec comptable',
  'registerAsAccountant': "S'inscrire en tant que comptable",
  'registerAsConsumer': "S'inscrire en tant que consommateur",
  'firmName': 'Nom du cabinet',
  'professionalRegNumber': "Numéro d'enregistrement professionnel",
  'taxNumber': 'Numéro fiscal',
  'address': 'Adresse',
  'verificationDocument': 'Document de vérification professionnelle',
  'uploadDocument': 'Télécharger le document',
  'subscriptionPlan': "Plan d'abonnement préféré",
  'planSolo': 'Comptable solo',
  'planProfessional': 'Cabinet professionnel',
  'planEnterprise': 'Cabinet entreprise',
  'accountantPendingTitle': "Demande en cours d'examen",
  'accountantPendingMessage':
      'Votre compte comptable est en attente de vérification.',
  'signOut': 'Se déconnecter',
  'homeGreeting': 'Bonjour, {name}',
  'searchReceipts': 'Rechercher des reçus',
  'scanReceipt': 'Scanner un reçu',
  'uploadReceipt': 'Télécharger un reçu',
  'addManually': 'Ajouter manuellement',
  'totalSpendingMonth': 'Dépenses ce mois-ci',
  'receiptsThisMonth': 'Reçus ce mois-ci',
  'activeWarranties': 'Garanties actives',
  'returnDeadlines': 'Délais de retour',
  'recentReceipts': 'Reçus récents',
  'noReceiptsYet': 'Pas encore de reçus',
  'noReceiptsHint': 'Scannez ou téléchargez votre premier reçu.',
  'navHome': 'Accueil',
  'navReceipts': 'Reçus',
  'navScan': 'Scanner',
  'navInsights': 'Analyses',
  'navProfile': 'Profil',
  'fieldRequired': 'Ce champ est obligatoire',
  'invalidEmail': 'Veuillez entrer une adresse e-mail valide',
  'passwordTooShort': 'Le mot de passe doit contenir au moins 8 caractères',
  'passwordsDoNotMatch': 'Les mots de passe ne correspondent pas',
  'mustAcceptTerms': 'Vous devez accepter les Conditions générales',
  'mustAcceptPrivacy': 'Vous devez accepter la Politique de confidentialité',
  'registrationSuccess': 'Compte créé avec succès',
  'loginFailed': 'Échec de la connexion. Vérifiez vos identifiants.',
  'genericError': "Une erreur s'est produite. Veuillez réessayer.",
};

// Portuguese, Spanish, Afrikaans, isiZulu — English fallback for MVP;
// full translations can be added before launch.
final _pt = Map<String, String>.from(_en)
  ..addAll({
    'tagline': 'Cada recibo. Um só lugar.',
    'signIn': 'Entrar',
    'createAccount': 'Criar conta',
    'language': 'Idioma',
  });

final _es = Map<String, String>.from(_en)
  ..addAll({
    'tagline': 'Cada recibo. Un solo lugar.',
    'signIn': 'Iniciar sesión',
    'createAccount': 'Crear cuenta',
    'language': 'Idioma',
  });

final _af = Map<String, String>.from(_en)
  ..addAll({
    'tagline': 'Elke kwitansie. Een plek.',
    'signIn': 'Teken in',
    'createAccount': 'Skep rekening',
    'language': 'Taal',
  });

final _zu = Map<String, String>.from(_en)
  ..addAll({
    'tagline': 'Wonke amarisidi. Endaweni eyodwa.',
    'signIn': 'Ngena',
    'createAccount': 'Dala i-akhawunti',
    'language': 'Ulimi',
  });
