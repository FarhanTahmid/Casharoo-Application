import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Spendroo'**
  String get appName;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUp;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get noAccount;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get haveAccount;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Your money and your shop, in one app.'**
  String get tagline;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get verifyEmailTitle;

  /// No description provided for @codeSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a code to {email}. Enter it below.'**
  String codeSentTo(String email);

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Send the code again'**
  String get resendCode;

  /// No description provided for @codeResent.
  ///
  /// In en, this message translates to:
  /// **'A new code is on its way.'**
  String get codeResent;

  /// No description provided for @useAnotherAccount.
  ///
  /// In en, this message translates to:
  /// **'Use another account'**
  String get useAnotherAccount;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we will send you a code.'**
  String get resetPasswordHint;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @setNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Set new password'**
  String get setNewPassword;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed. Log in with the new one.'**
  String get passwordChanged;

  /// No description provided for @offlineError.
  ///
  /// In en, this message translates to:
  /// **'No connection. Try again when you are online.'**
  String get offlineError;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'How will you use Spendroo?'**
  String get welcomeTitle;

  /// No description provided for @forMyself.
  ///
  /// In en, this message translates to:
  /// **'For myself'**
  String get forMyself;

  /// No description provided for @forMyselfHint.
  ///
  /// In en, this message translates to:
  /// **'Track accounts, spending and budgets.'**
  String get forMyselfHint;

  /// No description provided for @forMyBusiness.
  ///
  /// In en, this message translates to:
  /// **'For my business'**
  String get forMyBusiness;

  /// No description provided for @forMyBusinessHint.
  ///
  /// In en, this message translates to:
  /// **'Keep a cashbook for a shop or business.'**
  String get forMyBusinessHint;

  /// No description provided for @tryDemo.
  ///
  /// In en, this message translates to:
  /// **'Try a demo business'**
  String get tryDemo;

  /// No description provided for @tryDemoHint.
  ///
  /// In en, this message translates to:
  /// **'A sample shop with a few weeks of entries.'**
  String get tryDemoHint;

  /// No description provided for @businessName.
  ///
  /// In en, this message translates to:
  /// **'Business name'**
  String get businessName;

  /// No description provided for @createBusiness.
  ///
  /// In en, this message translates to:
  /// **'Create business'**
  String get createBusiness;

  /// No description provided for @needsConnection.
  ///
  /// In en, this message translates to:
  /// **'This needs an internet connection.'**
  String get needsConnection;

  /// No description provided for @personal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get personal;

  /// No description provided for @business.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get business;

  /// No description provided for @demo.
  ///
  /// In en, this message translates to:
  /// **'Demo'**
  String get demo;

  /// No description provided for @switchWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Switch workspace'**
  String get switchWorkspace;

  /// No description provided for @newBusiness.
  ///
  /// In en, this message translates to:
  /// **'New business'**
  String get newBusiness;

  /// No description provided for @deleteWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Delete this business'**
  String get deleteWorkspace;

  /// No description provided for @deleteWorkspaceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this business and all its cashbooks?'**
  String get deleteWorkspaceConfirm;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @budgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get budgets;

  /// No description provided for @accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// No description provided for @cashbooks.
  ///
  /// In en, this message translates to:
  /// **'Cashbooks'**
  String get cashbooks;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @totalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total balance'**
  String get totalBalance;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @spendingByCategory.
  ///
  /// In en, this message translates to:
  /// **'Spending by category'**
  String get spendingByCategory;

  /// No description provided for @noSpendingYet.
  ///
  /// In en, this message translates to:
  /// **'No spending this month yet.'**
  String get noSpendingYet;

  /// No description provided for @uncategorised.
  ///
  /// In en, this message translates to:
  /// **'Uncategorised'**
  String get uncategorised;

  /// No description provided for @addTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get addTransaction;

  /// No description provided for @editTransaction.
  ///
  /// In en, this message translates to:
  /// **'Edit transaction'**
  String get editTransaction;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet. Add your first one.'**
  String get noTransactions;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @amountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than zero'**
  String get amountInvalid;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @fromAccount.
  ///
  /// In en, this message translates to:
  /// **'From account'**
  String get fromAccount;

  /// No description provided for @toAccount.
  ///
  /// In en, this message translates to:
  /// **'To account'**
  String get toAccount;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this?'**
  String get deleteConfirm;

  /// No description provided for @sameAccountError.
  ///
  /// In en, this message translates to:
  /// **'Choose two different accounts'**
  String get sameAccountError;

  /// No description provided for @currencyMismatch.
  ///
  /// In en, this message translates to:
  /// **'Both accounts must use the same currency'**
  String get currencyMismatch;

  /// No description provided for @addAccount.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get addAccount;

  /// No description provided for @editAccount.
  ///
  /// In en, this message translates to:
  /// **'Edit account'**
  String get editAccount;

  /// No description provided for @accountName.
  ///
  /// In en, this message translates to:
  /// **'Account name'**
  String get accountName;

  /// No description provided for @accountKind.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get accountKind;

  /// No description provided for @kindCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get kindCash;

  /// No description provided for @kindBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get kindBank;

  /// No description provided for @kindSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get kindSavings;

  /// No description provided for @kindMobileMoney.
  ///
  /// In en, this message translates to:
  /// **'Mobile money'**
  String get kindMobileMoney;

  /// No description provided for @kindCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get kindCard;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @defaultCurrency.
  ///
  /// In en, this message translates to:
  /// **'Default currency'**
  String get defaultCurrency;

  /// No description provided for @defaultCurrencyHint.
  ///
  /// In en, this message translates to:
  /// **'New accounts, cashbooks and budgets start in it, and totals are shown in it. What you already have keeps its own.'**
  String get defaultCurrencyHint;

  /// No description provided for @currencyFixedHint.
  ///
  /// In en, this message translates to:
  /// **'The currency cannot be changed after this is created.'**
  String get currencyFixedHint;

  /// No description provided for @keypadClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get keypadClear;

  /// No description provided for @keypadBackspace.
  ///
  /// In en, this message translates to:
  /// **'Delete last'**
  String get keypadBackspace;

  /// No description provided for @keypadDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get keypadDone;

  /// No description provided for @openingBalance.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get openingBalance;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get nameRequired;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archived;

  /// No description provided for @addBudget.
  ///
  /// In en, this message translates to:
  /// **'Add budget'**
  String get addBudget;

  /// No description provided for @monthlyLimit.
  ///
  /// In en, this message translates to:
  /// **'Monthly limit'**
  String get monthlyLimit;

  /// No description provided for @noBudgets.
  ///
  /// In en, this message translates to:
  /// **'No budgets yet. Set a monthly limit for a category.'**
  String get noBudgets;

  /// No description provided for @spentOf.
  ///
  /// In en, this message translates to:
  /// **'{spent} of {limit}'**
  String spentOf(String spent, String limit);

  /// No description provided for @overBudget.
  ///
  /// In en, this message translates to:
  /// **'Over budget'**
  String get overBudget;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get newCategory;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryName;

  /// No description provided for @addCashbook.
  ///
  /// In en, this message translates to:
  /// **'Add cashbook'**
  String get addCashbook;

  /// No description provided for @cashbookName.
  ///
  /// In en, this message translates to:
  /// **'Cashbook name'**
  String get cashbookName;

  /// No description provided for @noCashbooks.
  ///
  /// In en, this message translates to:
  /// **'No cashbooks yet. Add one to start recording cash.'**
  String get noCashbooks;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @cashIn.
  ///
  /// In en, this message translates to:
  /// **'Cash in'**
  String get cashIn;

  /// No description provided for @cashOut.
  ///
  /// In en, this message translates to:
  /// **'Cash out'**
  String get cashOut;

  /// No description provided for @totalIn.
  ///
  /// In en, this message translates to:
  /// **'Total in'**
  String get totalIn;

  /// No description provided for @totalOut.
  ///
  /// In en, this message translates to:
  /// **'Total out'**
  String get totalOut;

  /// No description provided for @noEntries.
  ///
  /// In en, this message translates to:
  /// **'No entries yet. Use Cash in or Cash out below.'**
  String get noEntries;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @remarks.
  ///
  /// In en, this message translates to:
  /// **'Remarks'**
  String get remarks;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethod;

  /// No description provided for @newPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'New payment method'**
  String get newPaymentMethod;

  /// No description provided for @editEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get editEntry;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @byCategory.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get byCategory;

  /// No description provided for @byPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'By payment method'**
  String get byPaymentMethod;

  /// No description provided for @entriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No entries} =1{1 entry} other{{count} entries}}'**
  String entriesCount(int count);

  /// No description provided for @readOnly.
  ///
  /// In en, this message translates to:
  /// **'You can view this cashbook but not change it.'**
  String get readOnly;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @bangla.
  ///
  /// In en, this message translates to:
  /// **'বাংলা'**
  String get bangla;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get syncing;

  /// No description provided for @allSynced.
  ///
  /// In en, this message translates to:
  /// **'Everything is saved to the cloud'**
  String get allSynced;

  /// No description provided for @pendingChanges.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change waiting to sync} other{{count} changes waiting to sync}}'**
  String pendingChanges(int count);

  /// No description provided for @offlineStatus.
  ///
  /// In en, this message translates to:
  /// **'Offline. Changes are kept on this device and sync later.'**
  String get offlineStatus;

  /// No description provided for @syncError.
  ///
  /// In en, this message translates to:
  /// **'Sync problem: {message}'**
  String syncError(String message);

  /// No description provided for @notSynced.
  ///
  /// In en, this message translates to:
  /// **'Not synced'**
  String get notSynced;

  /// No description provided for @notSyncedHint.
  ///
  /// In en, this message translates to:
  /// **'The server refused these changes and they were undone on this device.'**
  String get notSyncedHint;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @logOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Log out? Data on this device is removed; everything already synced stays in your account.'**
  String get logOutConfirm;

  /// No description provided for @logOutUnsynced.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change has not synced and will be lost.} other{{count} changes have not synced and will be lost.}}'**
  String logOutUnsynced(int count);

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonth;

  /// No description provided for @budgetThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Budget this month'**
  String get budgetThisMonth;

  /// No description provided for @spent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get spent;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @dailyAllowance.
  ///
  /// In en, this message translates to:
  /// **'Daily allowance'**
  String get dailyAllowance;

  /// No description provided for @perDay.
  ///
  /// In en, this message translates to:
  /// **'{amount} a day'**
  String perDay(String amount);

  /// No description provided for @thisMonthOnly.
  ///
  /// In en, this message translates to:
  /// **'This month only'**
  String get thisMonthOnly;

  /// No description provided for @thisMonthOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Other months keep the usual limit.'**
  String get thisMonthOnlyHint;

  /// No description provided for @usualLimit.
  ///
  /// In en, this message translates to:
  /// **'Usual limit: {amount}'**
  String usualLimit(String amount);

  /// No description provided for @useUsualLimit.
  ///
  /// In en, this message translates to:
  /// **'Use usual limit'**
  String get useUsualLimit;

  /// No description provided for @noTransactionsOnDay.
  ///
  /// In en, this message translates to:
  /// **'Nothing recorded on this day.'**
  String get noTransactionsOnDay;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @noCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories yet.'**
  String get noCategories;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get editCategory;

  /// No description provided for @colour.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get colour;

  /// No description provided for @automaticColour.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get automaticColour;

  /// No description provided for @customColour.
  ///
  /// In en, this message translates to:
  /// **'Custom colour'**
  String get customColour;

  /// No description provided for @colourHue.
  ///
  /// In en, this message translates to:
  /// **'Hue'**
  String get colourHue;

  /// No description provided for @colourShade.
  ///
  /// In en, this message translates to:
  /// **'Shade'**
  String get colourShade;

  /// No description provided for @deleteCategoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? {count, plural, =0{Its budgets are removed.} =1{1 transaction stays, without a category, and its budgets are removed.} other{{count} transactions stay, without a category, and its budgets are removed.}}'**
  String deleteCategoryConfirm(String name, int count);

  /// No description provided for @net.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get net;

  /// No description provided for @lastSixMonths.
  ///
  /// In en, this message translates to:
  /// **'Last 6 months'**
  String get lastSixMonths;

  /// No description provided for @changeVsLastMonth.
  ///
  /// In en, this message translates to:
  /// **'{percent}% vs last month'**
  String changeVsLastMonth(String percent);

  /// No description provided for @newThisMonth.
  ///
  /// In en, this message translates to:
  /// **'New this month'**
  String get newThisMonth;

  /// No description provided for @accountBalances.
  ///
  /// In en, this message translates to:
  /// **'Account balances'**
  String get accountBalances;

  /// No description provided for @server.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get server;

  /// No description provided for @serverHint.
  ///
  /// In en, this message translates to:
  /// **'Address of the Spendroo API this test build talks to.'**
  String get serverHint;

  /// No description provided for @serverChangeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Switch server? You will be logged out and data on this device is removed.'**
  String get serverChangeConfirm;

  /// No description provided for @serverInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an address starting with http:// or https://'**
  String get serverInvalid;

  /// No description provided for @resetToDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get resetToDefault;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get sendFeedback;

  /// No description provided for @sendFeedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us what works and what does not.'**
  String get sendFeedbackHint;

  /// No description provided for @needsConnectionRetry.
  ///
  /// In en, this message translates to:
  /// **'This needs an internet connection. Try again when you are online.'**
  String get needsConnectionRetry;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchTransactions.
  ///
  /// In en, this message translates to:
  /// **'Search by note, category or amount'**
  String get searchTransactions;

  /// No description provided for @searchOrCreate.
  ///
  /// In en, this message translates to:
  /// **'Search or type a new name'**
  String get searchOrCreate;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @noResultsFor.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches \"{query}\".'**
  String noResultsFor(String query);

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches.'**
  String get noMatches;

  /// No description provided for @createNamed.
  ///
  /// In en, this message translates to:
  /// **'Create \"{name}\"'**
  String createNamed(String name);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @paceLeft.
  ///
  /// In en, this message translates to:
  /// **'{amount} left to spend'**
  String paceLeft(String amount);

  /// No description provided for @paceOver.
  ///
  /// In en, this message translates to:
  /// **'{amount} over budget'**
  String paceOver(String amount);

  /// No description provided for @emailOrUsername.
  ///
  /// In en, this message translates to:
  /// **'Email or username'**
  String get emailOrUsername;

  /// No description provided for @enterEmailOrUsername.
  ///
  /// In en, this message translates to:
  /// **'Enter your email or username'**
  String get enterEmailOrUsername;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match'**
  String get passwordsDontMatch;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @enterCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password'**
  String get enterCurrentPassword;

  /// No description provided for @passwordSameAsCurrent.
  ///
  /// In en, this message translates to:
  /// **'Choose a password different from your current one'**
  String get passwordSameAsCurrent;

  /// No description provided for @passwordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated.'**
  String get passwordUpdated;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @setPassword.
  ///
  /// In en, this message translates to:
  /// **'Set a password'**
  String get setPassword;

  /// No description provided for @setPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'You signed in with Google. Set a password to also log in with your email or username.'**
  String get setPasswordHint;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @profileHint.
  ///
  /// In en, this message translates to:
  /// **'Photo, username and password'**
  String get profileHint;

  /// No description provided for @profileDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get profileDetails;

  /// No description provided for @signInAndSecurity.
  ///
  /// In en, this message translates to:
  /// **'Sign-in and security'**
  String get signInAndSecurity;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get bio;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved.'**
  String get profileSaved;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'You can log in with it instead of your email.'**
  String get usernameHint;

  /// No description provided for @usernameChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get usernameChecking;

  /// No description provided for @usernameAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get usernameAvailable;

  /// No description provided for @usernameTaken.
  ///
  /// In en, this message translates to:
  /// **'Already taken'**
  String get usernameTaken;

  /// No description provided for @usernameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use letters, numbers and . _ + - only'**
  String get usernameInvalid;

  /// No description provided for @usernameYours.
  ///
  /// In en, this message translates to:
  /// **'This is your username'**
  String get usernameYours;

  /// No description provided for @usernameSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Free ones like it:'**
  String get usernameSuggestions;

  /// No description provided for @changeUsername.
  ///
  /// In en, this message translates to:
  /// **'Change username'**
  String get changeUsername;

  /// No description provided for @usernameChanged.
  ///
  /// In en, this message translates to:
  /// **'Username changed.'**
  String get usernameChanged;

  /// No description provided for @confirmWithPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to confirm this change.'**
  String get confirmWithPassword;

  /// No description provided for @confirmChange.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmChange;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @cropPhoto.
  ///
  /// In en, this message translates to:
  /// **'Crop photo'**
  String get cropPhoto;

  /// No description provided for @photoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated.'**
  String get photoUpdated;

  /// No description provided for @photoRemoved.
  ///
  /// In en, this message translates to:
  /// **'Profile photo removed.'**
  String get photoRemoved;

  /// No description provided for @plan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get plan;

  /// No description provided for @planYours.
  ///
  /// In en, this message translates to:
  /// **'Your plan'**
  String get planYours;

  /// No description provided for @planUntil.
  ///
  /// In en, this message translates to:
  /// **'Until {date}'**
  String planUntil(String date);

  /// No description provided for @planGraceNote.
  ///
  /// In en, this message translates to:
  /// **'Your payment is late. The plan stays on for a few more days.'**
  String get planGraceNote;

  /// No description provided for @planSeePlans.
  ///
  /// In en, this message translates to:
  /// **'See plans'**
  String get planSeePlans;

  /// No description provided for @planUsage.
  ///
  /// In en, this message translates to:
  /// **'What you are using'**
  String get planUsage;

  /// No description provided for @planCountOf.
  ///
  /// In en, this message translates to:
  /// **'{count} of {limit}'**
  String planCountOf(int count, int limit);

  /// No description provided for @planUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get planUnlimited;

  /// No description provided for @planResetsOn.
  ///
  /// In en, this message translates to:
  /// **'Starts again on {date}'**
  String planResetsOn(String date);

  /// No description provided for @planRedeem.
  ///
  /// In en, this message translates to:
  /// **'Redeem a code'**
  String get planRedeem;

  /// No description provided for @planRedeemHint.
  ///
  /// In en, this message translates to:
  /// **'Have a promo code? Enter it here.'**
  String get planRedeemHint;

  /// No description provided for @planCodeApplied.
  ///
  /// In en, this message translates to:
  /// **'Code applied. You are on the {plan} plan.'**
  String planCodeApplied(String plan);

  /// No description provided for @planThrottled.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Wait a while and try again.'**
  String get planThrottled;

  /// No description provided for @planUpgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Get more from Spendroo'**
  String get planUpgradeTitle;

  /// No description provided for @planBuySoon.
  ///
  /// In en, this message translates to:
  /// **'Buying a plan in the app is coming soon. If you have a code, use it below.'**
  String get planBuySoon;

  /// No description provided for @planSimulate.
  ///
  /// In en, this message translates to:
  /// **'Simulate purchase (test build)'**
  String get planSimulate;

  /// No description provided for @planSimulateExpire.
  ///
  /// In en, this message translates to:
  /// **'End my plan now (test build)'**
  String get planSimulateExpire;

  /// No description provided for @planLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load the plans. Check your connection.'**
  String get planLoadFailed;

  /// No description provided for @planOffers.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get planOffers;

  /// No description provided for @planUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get planUpgrade;

  /// No description provided for @planEverythingIn.
  ///
  /// In en, this message translates to:
  /// **'Everything in {plan}, and:'**
  String planEverythingIn(String plan);

  /// No description provided for @limitAccounts.
  ///
  /// In en, this message translates to:
  /// **'Your {plan} plan allows {limit, plural, =1{1 account} other{{limit} accounts}}.'**
  String limitAccounts(String plan, int limit);

  /// No description provided for @limitCategories.
  ///
  /// In en, this message translates to:
  /// **'Your {plan} plan allows {limit, plural, =1{1 category} other{{limit} categories}} of your own.'**
  String limitCategories(String plan, int limit);

  /// No description provided for @limitCashbooks.
  ///
  /// In en, this message translates to:
  /// **'Your {plan} plan allows {limit, plural, =1{1 cashbook} other{{limit} cashbooks}} in a business.'**
  String limitCashbooks(String plan, int limit);

  /// No description provided for @limitWorkspaces.
  ///
  /// In en, this message translates to:
  /// **'Your {plan} plan allows {limit, plural, =0{no business} =1{1 business} other{{limit} businesses}}.'**
  String limitWorkspaces(String plan, int limit);

  /// No description provided for @limitGeneric.
  ///
  /// In en, this message translates to:
  /// **'Your {plan} plan does not allow more of this.'**
  String limitGeneric(String plan);

  /// No description provided for @limitFeature.
  ///
  /// In en, this message translates to:
  /// **'{feature} is not part of your {plan} plan.'**
  String limitFeature(String feature, String plan);

  /// No description provided for @limitLocked.
  ///
  /// In en, this message translates to:
  /// **'This is read-only on your {plan} plan. Upgrade, or choose what to keep.'**
  String limitLocked(String plan);

  /// No description provided for @limitQuota.
  ///
  /// In en, this message translates to:
  /// **'This month\'s allowance is used up: {feature}.'**
  String limitQuota(String feature);

  /// No description provided for @featureAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get featureAccounts;

  /// No description provided for @featureCustomCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories of your own'**
  String get featureCustomCategories;

  /// No description provided for @featureBudgetMonthOverride.
  ///
  /// In en, this message translates to:
  /// **'A different budget for one month'**
  String get featureBudgetMonthOverride;

  /// No description provided for @featureInsightsCustomRange.
  ///
  /// In en, this message translates to:
  /// **'Insights for any dates'**
  String get featureInsightsCustomRange;

  /// No description provided for @featureYearReview.
  ///
  /// In en, this message translates to:
  /// **'Year in review'**
  String get featureYearReview;

  /// No description provided for @featureTrendMonths.
  ///
  /// In en, this message translates to:
  /// **'Months of trends'**
  String get featureTrendMonths;

  /// No description provided for @featureRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring transactions and reminders'**
  String get featureRecurring;

  /// No description provided for @featureSavingsGoals.
  ///
  /// In en, this message translates to:
  /// **'Savings goals'**
  String get featureSavingsGoals;

  /// No description provided for @featureHomeWidget.
  ///
  /// In en, this message translates to:
  /// **'Home screen widget'**
  String get featureHomeWidget;

  /// No description provided for @featureBusinesses.
  ///
  /// In en, this message translates to:
  /// **'Businesses'**
  String get featureBusinesses;

  /// No description provided for @featureCashbooks.
  ///
  /// In en, this message translates to:
  /// **'Cashbooks in a business'**
  String get featureCashbooks;

  /// No description provided for @featureTeamSeats.
  ///
  /// In en, this message translates to:
  /// **'Team members'**
  String get featureTeamSeats;

  /// No description provided for @featureReportRange.
  ///
  /// In en, this message translates to:
  /// **'Reports for any dates'**
  String get featureReportRange;

  /// No description provided for @featureReportExport.
  ///
  /// In en, this message translates to:
  /// **'Reports as PDF and Excel'**
  String get featureReportExport;

  /// No description provided for @featureAuditTrail.
  ///
  /// In en, this message translates to:
  /// **'History of every change'**
  String get featureAuditTrail;

  /// No description provided for @featureCustomFields.
  ///
  /// In en, this message translates to:
  /// **'Extra fields on entries'**
  String get featureCustomFields;

  /// No description provided for @featureStorage.
  ///
  /// In en, this message translates to:
  /// **'Storage for bills, in MB'**
  String get featureStorage;

  /// No description provided for @featureAiCredits.
  ///
  /// In en, this message translates to:
  /// **'AI credits a month'**
  String get featureAiCredits;

  /// No description provided for @featurePdfPages.
  ///
  /// In en, this message translates to:
  /// **'Statement pages read a month'**
  String get featurePdfPages;

  /// No description provided for @featureDevices.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get featureDevices;

  /// No description provided for @featureNoAds.
  ///
  /// In en, this message translates to:
  /// **'No ads'**
  String get featureNoAds;

  /// No description provided for @keepTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose what to keep'**
  String get keepTitle;

  /// No description provided for @keepIntro.
  ///
  /// In en, this message translates to:
  /// **'Your plan now allows fewer than you have. Choose the ones to go on editing. The rest stay safe and readable; nothing is deleted.'**
  String get keepIntro;

  /// No description provided for @keepChosen.
  ///
  /// In en, this message translates to:
  /// **'{chosen} of {limit} chosen'**
  String keepChosen(int chosen, int limit);

  /// No description provided for @keepSave.
  ///
  /// In en, this message translates to:
  /// **'Keep these'**
  String get keepSave;

  /// No description provided for @keepSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved. The others are read-only.'**
  String get keepSaved;

  /// No description provided for @keepChangeFrom.
  ///
  /// In en, this message translates to:
  /// **'You can change this again from {date}.'**
  String keepChangeFrom(String date);

  /// No description provided for @keepPendingNote.
  ///
  /// In en, this message translates to:
  /// **'Until you choose, the oldest ones stay editable.'**
  String get keepPendingNote;

  /// No description provided for @keepOnceNote.
  ///
  /// In en, this message translates to:
  /// **'Choose with care: after saving, this cannot be changed for a while.'**
  String get keepOnceNote;

  /// No description provided for @keepNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing is locked. Everything you have fits your plan.'**
  String get keepNothing;

  /// No description provided for @keepIn.
  ///
  /// In en, this message translates to:
  /// **'{feature} in {workspace}'**
  String keepIn(String feature, String workspace);

  /// No description provided for @keepLockedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item is read-only} other{{count} items are read-only}}'**
  String keepLockedCount(int count);

  /// No description provided for @keepOffline.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to change this.'**
  String get keepOffline;

  /// No description provided for @defaultTag.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultTag;

  /// No description provided for @customCount.
  ///
  /// In en, this message translates to:
  /// **'Your own: {count} of {limit}'**
  String customCount(int count, int limit);

  /// No description provided for @offerEnds.
  ///
  /// In en, this message translates to:
  /// **'Ends {date}'**
  String offerEnds(String date);

  /// No description provided for @offerClaim.
  ///
  /// In en, this message translates to:
  /// **'Get it'**
  String get offerClaim;

  /// No description provided for @offerClaimed.
  ///
  /// In en, this message translates to:
  /// **'It is yours now. Enjoy!'**
  String get offerClaimed;

  /// No description provided for @offerActive.
  ///
  /// In en, this message translates to:
  /// **'On for you'**
  String get offerActive;

  /// No description provided for @lockedTag.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get lockedTag;

  /// No description provided for @spendInsightTop.
  ///
  /// In en, this message translates to:
  /// **'{name} takes {percent}% of what you spent.'**
  String spendInsightTop(String name, String percent);

  /// No description provided for @spendInsightRise.
  ///
  /// In en, this message translates to:
  /// **'{name} is up {percent}% on last month.'**
  String spendInsightRise(String name, String percent);

  /// No description provided for @spendTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a category for details'**
  String get spendTapHint;

  /// No description provided for @shareOfSpending.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of spending'**
  String shareOfSpending(String percent);

  /// No description provided for @statAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get statAverage;

  /// No description provided for @statLargest.
  ///
  /// In en, this message translates to:
  /// **'Largest'**
  String get statLargest;

  /// No description provided for @moreCategories.
  ///
  /// In en, this message translates to:
  /// **'{count} more'**
  String moreCategories(String count);

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
