// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Casharoo';

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
  String get welcomeTitle => 'How will you use Casharoo?';

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
}
