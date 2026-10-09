// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Spendroo';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get newPassword => 'New password';

  @override
  String get logIn => 'Log in';

  @override
  String get signUp => 'Create account';

  @override
  String get noAccount => 'New here? Create an account';

  @override
  String get haveAccount => 'Already have an account? Log in';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get tagline => 'Your money and your shop, in one app.';

  @override
  String get enterEmail => 'Enter a valid email';

  @override
  String get passwordTooShort => 'Use at least 8 characters';

  @override
  String get verifyEmailTitle => 'Check your email';

  @override
  String codeSentTo(String email) {
    return 'We sent a code to $email. Enter it below.';
  }

  @override
  String get code => 'Code';

  @override
  String get verify => 'Verify';

  @override
  String get resendCode => 'Send the code again';

  @override
  String get codeResent => 'A new code is on its way.';

  @override
  String get useAnotherAccount => 'Use another account';

  @override
  String get resetPasswordTitle => 'Reset password';

  @override
  String get resetPasswordHint =>
      'Enter your email and we will send you a code.';

  @override
  String get sendCode => 'Send code';

  @override
  String get setNewPassword => 'Set new password';

  @override
  String get passwordChanged => 'Password changed. Log in with the new one.';

  @override
  String get offlineError => 'No connection. Try again when you are online.';

  @override
  String get welcomeTitle => 'How will you use Spendroo?';

  @override
  String get forMyself => 'For myself';

  @override
  String get forMyselfHint => 'Track accounts, spending and budgets.';

  @override
  String get forMyBusiness => 'For my business';

  @override
  String get forMyBusinessHint => 'Keep a cashbook for a shop or business.';

  @override
  String get tryDemo => 'Try a demo business';

  @override
  String get tryDemoHint => 'A sample shop with a few weeks of entries.';

  @override
  String get businessName => 'Business name';

  @override
  String get createBusiness => 'Create business';

  @override
  String get needsConnection => 'This needs an internet connection.';

  @override
  String get personal => 'Personal';

  @override
  String get business => 'Business';

  @override
  String get demo => 'Demo';

  @override
  String get switchWorkspace => 'Switch workspace';

  @override
  String get newBusiness => 'New business';

  @override
  String get deleteWorkspace => 'Delete this business';

  @override
  String get deleteWorkspaceConfirm =>
      'Delete this business and all its cashbooks?';

  @override
  String get overview => 'Overview';

  @override
  String get transactions => 'Transactions';

  @override
  String get budgets => 'Budgets';

  @override
  String get accounts => 'Accounts';

  @override
  String get cashbooks => 'Cashbooks';

  @override
  String get settings => 'Settings';

  @override
  String get totalBalance => 'Total balance';

  @override
  String get thisMonth => 'This month';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get transfer => 'Transfer';

  @override
  String get spendingByCategory => 'Spending by category';

  @override
  String get noSpendingYet => 'No spending this month yet.';

  @override
  String get uncategorised => 'Uncategorised';

  @override
  String get addTransaction => 'Add transaction';

  @override
  String get editTransaction => 'Edit transaction';

  @override
  String get noTransactions => 'No transactions yet. Add your first one.';

  @override
  String get amount => 'Amount';

  @override
  String get amountInvalid => 'Enter an amount greater than zero';

  @override
  String get account => 'Account';

  @override
  String get fromAccount => 'From account';

  @override
  String get toAccount => 'To account';

  @override
  String get category => 'Category';

  @override
  String get none => 'None';

  @override
  String get date => 'Date';

  @override
  String get note => 'Note';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get deleteConfirm => 'Delete this?';

  @override
  String get sameAccountError => 'Choose two different accounts';

  @override
  String get currencyMismatch => 'Both accounts must use the same currency';

  @override
  String get addAccount => 'Add account';

  @override
  String get editAccount => 'Edit account';

  @override
  String get accountName => 'Account name';

  @override
  String get accountKind => 'Type';

  @override
  String get kindCash => 'Cash';

  @override
  String get kindBank => 'Bank';

  @override
  String get kindSavings => 'Savings';

  @override
  String get kindMobileMoney => 'Mobile money';

  @override
  String get kindCard => 'Card';

  @override
  String get currency => 'Currency';

  @override
  String get defaultCurrency => 'Default currency';

  @override
  String get defaultCurrencyHint =>
      'New accounts, cashbooks and budgets start in it, and totals are shown in it. What you already have keeps its own.';

  @override
  String get currencyFixedHint =>
      'The currency cannot be changed after this is created.';

  @override
  String get keypadClear => 'Clear';

  @override
  String get keypadBackspace => 'Delete last';

  @override
  String get keypadDone => 'Done';

  @override
  String get openingBalance => 'Opening balance';

  @override
  String get nameRequired => 'Enter a name';

  @override
  String get archive => 'Archive';

  @override
  String get archived => 'Archived';

  @override
  String get addBudget => 'Add budget';

  @override
  String get monthlyLimit => 'Monthly limit';

  @override
  String get noBudgets => 'No budgets yet. Set a monthly limit for a category.';

  @override
  String spentOf(String spent, String limit) {
    return '$spent of $limit';
  }

  @override
  String get overBudget => 'Over budget';

  @override
  String get newCategory => 'New category';

  @override
  String get categoryName => 'Category name';

  @override
  String get addCashbook => 'Add cashbook';

  @override
  String get cashbookName => 'Cashbook name';

  @override
  String get noCashbooks =>
      'No cashbooks yet. Add one to start recording cash.';

  @override
  String get balance => 'Balance';

  @override
  String get cashIn => 'Cash in';

  @override
  String get cashOut => 'Cash out';

  @override
  String get totalIn => 'Total in';

  @override
  String get totalOut => 'Total out';

  @override
  String get noEntries => 'No entries yet. Use Cash in or Cash out below.';

  @override
  String get title => 'Title';

  @override
  String get remarks => 'Remarks';

  @override
  String get paymentMethod => 'Payment method';

  @override
  String get newPaymentMethod => 'New payment method';

  @override
  String get editEntry => 'Edit entry';

  @override
  String get rename => 'Rename';

  @override
  String get report => 'Report';

  @override
  String get byCategory => 'By category';

  @override
  String get byPaymentMethod => 'By payment method';

  @override
  String entriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries',
      one: '1 entry',
      zero: 'No entries',
    );
    return '$_temp0';
  }

  @override
  String get readOnly => 'You can view this cashbook but not change it.';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get bangla => 'বাংলা';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get sync => 'Sync';

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncing => 'Syncing…';

  @override
  String get allSynced => 'Everything is saved to the cloud';

  @override
  String pendingChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes waiting to sync',
      one: '1 change waiting to sync',
    );
    return '$_temp0';
  }

  @override
  String get offlineStatus =>
      'Offline. Changes are kept on this device and sync later.';

  @override
  String syncError(String message) {
    return 'Sync problem: $message';
  }

  @override
  String get notSynced => 'Not synced';

  @override
  String get notSyncedHint =>
      'The server refused these changes and they were undone on this device.';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get logOut => 'Log out';

  @override
  String get logOutConfirm =>
      'Log out? Data on this device is removed; everything already synced stays in your account.';

  @override
  String logOutUnsynced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes have not synced and will be lost.',
      one: '1 change has not synced and will be lost.',
    );
    return '$_temp0';
  }

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get budgetThisMonth => 'Budget this month';

  @override
  String get spent => 'Spent';

  @override
  String get remaining => 'Remaining';

  @override
  String get dailyAllowance => 'Daily allowance';

  @override
  String perDay(String amount) {
    return '$amount a day';
  }

  @override
  String get thisMonthOnly => 'This month only';

  @override
  String get thisMonthOnlyHint => 'Other months keep the usual limit.';

  @override
  String usualLimit(String amount) {
    return 'Usual limit: $amount';
  }

  @override
  String get useUsualLimit => 'Use usual limit';

  @override
  String get noTransactionsOnDay => 'Nothing recorded on this day.';

  @override
  String get categories => 'Categories';

  @override
  String get noCategories => 'No categories yet.';

  @override
  String get renameCategory => 'Rename category';

  @override
  String deleteCategoryConfirm(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count transactions stay, without a category, and its budgets are removed.',
      one:
          '1 transaction stays, without a category, and its budgets are removed.',
      zero: 'Its budgets are removed.',
    );
    return 'Delete \"$name\"? $_temp0';
  }

  @override
  String get net => 'Net';

  @override
  String get lastSixMonths => 'Last 6 months';

  @override
  String get topCategories => 'Top spending';

  @override
  String changeVsLastMonth(String percent) {
    return '$percent% vs last month';
  }

  @override
  String get newThisMonth => 'New this month';

  @override
  String get accountBalances => 'Account balances';

  @override
  String get server => 'Server';

  @override
  String get serverHint =>
      'Address of the Spendroo API this test build talks to.';

  @override
  String get serverChangeConfirm =>
      'Switch server? You will be logged out and data on this device is removed.';

  @override
  String get serverInvalid =>
      'Enter an address starting with http:// or https://';

  @override
  String get resetToDefault => 'Reset to default';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get sendFeedback => 'Send feedback';

  @override
  String get sendFeedbackHint => 'Tell us what works and what does not.';

  @override
  String get needsConnectionRetry =>
      'This needs an internet connection. Try again when you are online.';

  @override
  String get retry => 'Retry';

  @override
  String get search => 'Search';

  @override
  String get searchTransactions => 'Search by note, category or amount';

  @override
  String get searchOrCreate => 'Search or type a new name';

  @override
  String get filterAll => 'All';

  @override
  String noResultsFor(String query) {
    return 'Nothing matches \"$query\".';
  }

  @override
  String get noMatches => 'Nothing matches.';

  @override
  String createNamed(String name) {
    return 'Create \"$name\"';
  }

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String paceLeft(String amount) {
    return '$amount left to spend';
  }

  @override
  String paceOver(String amount) {
    return '$amount over budget';
  }

  @override
  String get emailOrUsername => 'Email or username';

  @override
  String get enterEmailOrUsername => 'Enter your email or username';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get confirmNewPassword => 'Confirm new password';

  @override
  String get passwordsDontMatch => 'Passwords don\'t match';

  @override
  String get currentPassword => 'Current password';

  @override
  String get enterCurrentPassword => 'Enter your current password';

  @override
  String get passwordSameAsCurrent =>
      'Choose a password different from your current one';

  @override
  String get passwordUpdated => 'Password updated.';

  @override
  String get changePassword => 'Change password';

  @override
  String get setPassword => 'Set a password';

  @override
  String get setPasswordHint =>
      'You signed in with Google. Set a password to also log in with your email or username.';

  @override
  String get profile => 'Profile';

  @override
  String get profileHint => 'Photo, username and password';

  @override
  String get profileDetails => 'Details';

  @override
  String get signInAndSecurity => 'Sign-in and security';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get bio => 'About you';

  @override
  String get phone => 'Phone';

  @override
  String get profileSaved => 'Profile saved.';

  @override
  String get username => 'Username';

  @override
  String get usernameHint => 'You can log in with it instead of your email.';

  @override
  String get usernameChecking => 'Checking…';

  @override
  String get usernameAvailable => 'Available';

  @override
  String get usernameTaken => 'Already taken';

  @override
  String get usernameInvalid => 'Use letters, numbers and . _ + - only';

  @override
  String get usernameYours => 'This is your username';

  @override
  String get usernameSuggestions => 'Free ones like it:';

  @override
  String get changeUsername => 'Change username';

  @override
  String get usernameChanged => 'Username changed.';

  @override
  String get confirmWithPassword =>
      'Enter your password to confirm this change.';

  @override
  String get confirmChange => 'Confirm';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get cropPhoto => 'Crop photo';

  @override
  String get photoUpdated => 'Profile photo updated.';

  @override
  String get photoRemoved => 'Profile photo removed.';

  @override
  String get plan => 'Plan';

  @override
  String get planYours => 'Your plan';

  @override
  String planUntil(String date) {
    return 'Until $date';
  }

  @override
  String get planGraceNote =>
      'Your payment is late. The plan stays on for a few more days.';

  @override
  String get planSeePlans => 'See plans';

  @override
  String get planUsage => 'What you are using';

  @override
  String planCountOf(int count, int limit) {
    return '$count of $limit';
  }

  @override
  String get planUnlimited => 'Unlimited';

  @override
  String planResetsOn(String date) {
    return 'Starts again on $date';
  }

  @override
  String get planRedeem => 'Redeem a code';

  @override
  String get planRedeemHint => 'Have a promo code? Enter it here.';

  @override
  String planCodeApplied(String plan) {
    return 'Code applied. You are on the $plan plan.';
  }

  @override
  String get planThrottled => 'Too many tries. Wait a while and try again.';

  @override
  String get planUpgradeTitle => 'Get more from Spendroo';

  @override
  String get planBuySoon =>
      'Buying a plan in the app is coming soon. If you have a code, use it below.';

  @override
  String get planSimulate => 'Simulate purchase (test build)';

  @override
  String get planSimulateExpire => 'End my plan now (test build)';

  @override
  String get planLoadFailed =>
      'Could not load the plans. Check your connection.';

  @override
  String get planOffers => 'Offers';

  @override
  String get planUpgrade => 'Upgrade';

  @override
  String planEverythingIn(String plan) {
    return 'Everything in $plan, and:';
  }

  @override
  String limitAccounts(String plan, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: '$limit accounts',
      one: '1 account',
    );
    return 'Your $plan plan allows $_temp0.';
  }

  @override
  String limitCategories(String plan, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: '$limit categories',
      one: '1 category',
    );
    return 'Your $plan plan allows $_temp0 of your own.';
  }

  @override
  String limitCashbooks(String plan, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: '$limit cashbooks',
      one: '1 cashbook',
    );
    return 'Your $plan plan allows $_temp0 in a business.';
  }

  @override
  String limitWorkspaces(String plan, int limit) {
    String _temp0 = intl.Intl.pluralLogic(
      limit,
      locale: localeName,
      other: '$limit businesses',
      one: '1 business',
      zero: 'no business',
    );
    return 'Your $plan plan allows $_temp0.';
  }

  @override
  String limitGeneric(String plan) {
    return 'Your $plan plan does not allow more of this.';
  }

  @override
  String limitFeature(String feature, String plan) {
    return '$feature is not part of your $plan plan.';
  }

  @override
  String limitLocked(String plan) {
    return 'This is read-only on your $plan plan. Upgrade, or choose what to keep.';
  }

  @override
  String limitQuota(String feature) {
    return 'This month\'s allowance is used up: $feature.';
  }

  @override
  String get featureAccounts => 'Accounts';

  @override
  String get featureCustomCategories => 'Categories of your own';

  @override
  String get featureBudgetMonthOverride => 'A different budget for one month';

  @override
  String get featureInsightsCustomRange => 'Insights for any dates';

  @override
  String get featureYearReview => 'Year in review';

  @override
  String get featureTrendMonths => 'Months of trends';

  @override
  String get featureRecurring => 'Recurring transactions and reminders';

  @override
  String get featureSavingsGoals => 'Savings goals';

  @override
  String get featureHomeWidget => 'Home screen widget';

  @override
  String get featureBusinesses => 'Businesses';

  @override
  String get featureCashbooks => 'Cashbooks in a business';

  @override
  String get featureTeamSeats => 'Team members';

  @override
  String get featureReportRange => 'Reports for any dates';

  @override
  String get featureReportExport => 'Reports as PDF and Excel';

  @override
  String get featureAuditTrail => 'History of every change';

  @override
  String get featureCustomFields => 'Extra fields on entries';

  @override
  String get featureStorage => 'Storage for bills, in MB';

  @override
  String get featureAiCredits => 'AI credits a month';

  @override
  String get featurePdfPages => 'Statement pages read a month';

  @override
  String get featureDevices => 'Devices';

  @override
  String get featureNoAds => 'No ads';

  @override
  String get keepTitle => 'Choose what to keep';

  @override
  String get keepIntro =>
      'Your plan now allows fewer than you have. Choose the ones to go on editing. The rest stay safe and readable; nothing is deleted.';

  @override
  String keepChosen(int chosen, int limit) {
    return '$chosen of $limit chosen';
  }

  @override
  String get keepSave => 'Keep these';

  @override
  String get keepSaved => 'Saved. The others are read-only.';

  @override
  String keepChangeFrom(String date) {
    return 'You can change this again from $date.';
  }

  @override
  String get keepPendingNote =>
      'Until you choose, the oldest ones stay editable.';

  @override
  String get keepOnceNote =>
      'Choose with care: after saving, this cannot be changed for a while.';

  @override
  String get keepNothing =>
      'Nothing is locked. Everything you have fits your plan.';

  @override
  String keepIn(String feature, String workspace) {
    return '$feature in $workspace';
  }

  @override
  String keepLockedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items are read-only',
      one: '1 item is read-only',
    );
    return '$_temp0';
  }

  @override
  String get keepOffline => 'Connect to the internet to change this.';

  @override
  String get defaultTag => 'Default';

  @override
  String customCount(int count, int limit) {
    return 'Your own: $count of $limit';
  }

  @override
  String offerEnds(String date) {
    return 'Ends $date';
  }

  @override
  String get offerClaim => 'Get it';

  @override
  String get offerClaimed => 'It is yours now. Enjoy!';

  @override
  String get offerActive => 'On for you';

  @override
  String get lockedTag => 'Locked';
}
