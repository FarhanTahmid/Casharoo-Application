// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appName => 'ক্যাশারু';

  @override
  String get email => 'ইমেইল';

  @override
  String get password => 'পাসওয়ার্ড';

  @override
  String get newPassword => 'নতুন পাসওয়ার্ড';

  @override
  String get logIn => 'লগ ইন';

  @override
  String get signUp => 'অ্যাকাউন্ট খুলুন';

  @override
  String get noAccount => 'নতুন এসেছেন? অ্যাকাউন্ট খুলুন';

  @override
  String get haveAccount => 'আগে থেকেই অ্যাকাউন্ট আছে? লগ ইন করুন';

  @override
  String get forgotPassword => 'পাসওয়ার্ড ভুলে গেছেন?';

  @override
  String get continueWithGoogle => 'Google দিয়ে চালিয়ে যান';

  @override
  String get tagline => 'আপনার টাকা আর আপনার দোকান, এক অ্যাপে।';

  @override
  String get enterEmail => 'সঠিক ইমেইল লিখুন';

  @override
  String get passwordTooShort => 'কমপক্ষে ৮টি অক্ষর দিন';

  @override
  String get verifyEmailTitle => 'আপনার ইমেইল দেখুন';

  @override
  String codeSentTo(String email) {
    return '$email ঠিকানায় একটি কোড পাঠানো হয়েছে। নিচে লিখুন।';
  }

  @override
  String get code => 'কোড';

  @override
  String get verify => 'যাচাই করুন';

  @override
  String get resendCode => 'কোড আবার পাঠান';

  @override
  String get codeResent => 'নতুন কোড পাঠানো হয়েছে।';

  @override
  String get useAnotherAccount => 'অন্য অ্যাকাউন্ট ব্যবহার করুন';

  @override
  String get resetPasswordTitle => 'পাসওয়ার্ড রিসেট';

  @override
  String get resetPasswordHint => 'আপনার ইমেইল লিখুন, আমরা একটি কোড পাঠাব।';

  @override
  String get sendCode => 'কোড পাঠান';

  @override
  String get setNewPassword => 'নতুন পাসওয়ার্ড দিন';

  @override
  String get passwordChanged =>
      'পাসওয়ার্ড বদলানো হয়েছে। নতুন পাসওয়ার্ড দিয়ে লগ ইন করুন।';

  @override
  String get offlineError =>
      'ইন্টারনেট সংযোগ নেই। অনলাইনে এসে আবার চেষ্টা করুন।';

  @override
  String get welcomeTitle => 'ক্যাশারু কীভাবে ব্যবহার করবেন?';

  @override
  String get forMyself => 'নিজের জন্য';

  @override
  String get forMyselfHint => 'অ্যাকাউন্ট, খরচ আর বাজেটের হিসাব রাখুন।';

  @override
  String get forMyBusiness => 'ব্যবসার জন্য';

  @override
  String get forMyBusinessHint => 'দোকান বা ব্যবসার ক্যাশবুক রাখুন।';

  @override
  String get tryDemo => 'ডেমো ব্যবসা দেখুন';

  @override
  String get tryDemoHint => 'কয়েক সপ্তাহের হিসাবসহ একটি নমুনা দোকান।';

  @override
  String get businessName => 'ব্যবসার নাম';

  @override
  String get createBusiness => 'ব্যবসা তৈরি করুন';

  @override
  String get needsConnection => 'এর জন্য ইন্টারনেট সংযোগ লাগবে।';

  @override
  String get personal => 'ব্যক্তিগত';

  @override
  String get business => 'ব্যবসা';

  @override
  String get demo => 'ডেমো';

  @override
  String get switchWorkspace => 'ওয়ার্কস্পেস বদলান';

  @override
  String get newBusiness => 'নতুন ব্যবসা';

  @override
  String get deleteWorkspace => 'এই ব্যবসা মুছুন';

  @override
  String get deleteWorkspaceConfirm =>
      'এই ব্যবসা ও এর সব ক্যাশবুক মুছে ফেলবেন?';

  @override
  String get overview => 'সারসংক্ষেপ';

  @override
  String get transactions => 'লেনদেন';

  @override
  String get budgets => 'বাজেট';

  @override
  String get accounts => 'অ্যাকাউন্ট';

  @override
  String get cashbooks => 'ক্যাশবুক';

  @override
  String get settings => 'সেটিংস';

  @override
  String get totalBalance => 'মোট ব্যালেন্স';

  @override
  String get thisMonth => 'এই মাস';

  @override
  String get income => 'আয়';

  @override
  String get expense => 'খরচ';

  @override
  String get transfer => 'স্থানান্তর';

  @override
  String get spendingByCategory => 'খাত অনুযায়ী খরচ';

  @override
  String get noSpendingYet => 'এই মাসে এখনো কোনো খরচ নেই।';

  @override
  String get uncategorised => 'খাত ছাড়া';

  @override
  String get addTransaction => 'লেনদেন যোগ করুন';

  @override
  String get editTransaction => 'লেনদেন সম্পাদনা';

  @override
  String get noTransactions => 'এখনো কোনো লেনদেন নেই। প্রথমটি যোগ করুন।';

  @override
  String get amount => 'পরিমাণ';

  @override
  String get amountInvalid => 'শূন্যের বেশি পরিমাণ লিখুন';

  @override
  String get account => 'অ্যাকাউন্ট';

  @override
  String get fromAccount => 'যে অ্যাকাউন্ট থেকে';

  @override
  String get toAccount => 'যে অ্যাকাউন্টে';

  @override
  String get category => 'খাত';

  @override
  String get none => 'নেই';

  @override
  String get date => 'তারিখ';

  @override
  String get note => 'নোট';

  @override
  String get save => 'সংরক্ষণ';

  @override
  String get delete => 'মুছুন';

  @override
  String get cancel => 'বাতিল';

  @override
  String get deleteConfirm => 'এটি মুছে ফেলবেন?';

  @override
  String get sameAccountError => 'দুটি আলাদা অ্যাকাউন্ট বেছে নিন';

  @override
  String get currencyMismatch => 'দুই অ্যাকাউন্টের মুদ্রা একই হতে হবে';

  @override
  String get addAccount => 'অ্যাকাউন্ট যোগ করুন';

  @override
  String get editAccount => 'অ্যাকাউন্ট সম্পাদনা';

  @override
  String get accountName => 'অ্যাকাউন্টের নাম';

  @override
  String get accountKind => 'ধরন';

  @override
  String get kindCash => 'নগদ';

  @override
  String get kindBank => 'ব্যাংক';

  @override
  String get kindSavings => 'সঞ্চয়';

  @override
  String get kindMobileMoney => 'মোবাইল ব্যাংকিং';

  @override
  String get kindCard => 'কার্ড';

  @override
  String get currency => 'মুদ্রা';

  @override
  String get openingBalance => 'প্রারম্ভিক ব্যালেন্স';

  @override
  String get nameRequired => 'নাম লিখুন';

  @override
  String get archive => 'আর্কাইভ';

  @override
  String get archived => 'আর্কাইভ করা';

  @override
  String get addBudget => 'বাজেট যোগ করুন';

  @override
  String get monthlyLimit => 'মাসিক সীমা';

  @override
  String get noBudgets =>
      'এখনো কোনো বাজেট নেই। কোনো খাতের মাসিক সীমা ঠিক করুন।';

  @override
  String spentOf(String spent, String limit) {
    return '$limit এর মধ্যে $spent';
  }

  @override
  String get overBudget => 'বাজেট ছাড়িয়েছে';

  @override
  String get newCategory => 'নতুন খাত';

  @override
  String get categoryName => 'খাতের নাম';

  @override
  String get addCashbook => 'ক্যাশবুক যোগ করুন';

  @override
  String get cashbookName => 'ক্যাশবুকের নাম';

  @override
  String get noCashbooks =>
      'এখনো কোনো ক্যাশবুক নেই। নগদের হিসাব শুরু করতে একটি যোগ করুন।';

  @override
  String get balance => 'ব্যালেন্স';

  @override
  String get cashIn => 'জমা';

  @override
  String get cashOut => 'খরচ';

  @override
  String get totalIn => 'মোট জমা';

  @override
  String get totalOut => 'মোট খরচ';

  @override
  String get noEntries =>
      'এখনো কোনো এন্ট্রি নেই। নিচের জমা বা খরচ বোতাম ব্যবহার করুন।';

  @override
  String get title => 'শিরোনাম';

  @override
  String get remarks => 'মন্তব্য';

  @override
  String get paymentMethod => 'পরিশোধের মাধ্যম';

  @override
  String get newPaymentMethod => 'নতুন পরিশোধের মাধ্যম';

  @override
  String get editEntry => 'এন্ট্রি সম্পাদনা';

  @override
  String get rename => 'নাম বদলান';

  @override
  String get report => 'রিপোর্ট';

  @override
  String get byCategory => 'খাত অনুযায়ী';

  @override
  String get byPaymentMethod => 'পরিশোধের মাধ্যম অনুযায়ী';

  @override
  String entriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি এন্ট্রি',
      zero: 'কোনো এন্ট্রি নেই',
    );
    return '$_temp0';
  }

  @override
  String get readOnly => 'আপনি এই ক্যাশবুক দেখতে পারবেন, বদলাতে পারবেন না।';

  @override
  String get language => 'ভাষা';

  @override
  String get english => 'English';

  @override
  String get bangla => 'বাংলা';

  @override
  String get theme => 'থিম';

  @override
  String get themeSystem => 'সিস্টেম';

  @override
  String get themeLight => 'লাইট';

  @override
  String get themeDark => 'ডার্ক';

  @override
  String get sync => 'সিঙ্ক';

  @override
  String get syncNow => 'এখনই সিঙ্ক করুন';

  @override
  String get syncing => 'সিঙ্ক হচ্ছে…';

  @override
  String get allSynced => 'সবকিছু ক্লাউডে সংরক্ষিত আছে';

  @override
  String pendingChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি পরিবর্তন সিঙ্কের অপেক্ষায়',
    );
    return '$_temp0';
  }

  @override
  String get offlineStatus =>
      'অফলাইন। পরিবর্তনগুলো এই ডিভাইসে রাখা আছে, পরে সিঙ্ক হবে।';

  @override
  String syncError(String message) {
    return 'সিঙ্কে সমস্যা: $message';
  }

  @override
  String get notSynced => 'সিঙ্ক হয়নি';

  @override
  String get notSyncedHint =>
      'সার্ভার এই পরিবর্তনগুলো গ্রহণ করেনি, তাই এই ডিভাইসে সেগুলো বাতিল করা হয়েছে।';

  @override
  String get dismiss => 'সরান';

  @override
  String get logOut => 'লগ আউট';

  @override
  String get logOutConfirm =>
      'লগ আউট করবেন? এই ডিভাইসের তথ্য মুছে যাবে; যা সিঙ্ক হয়েছে তা আপনার অ্যাকাউন্টে থাকবে।';

  @override
  String logOutUnsynced(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি পরিবর্তন সিঙ্ক হয়নি এবং হারিয়ে যাবে।',
    );
    return '$_temp0';
  }

  @override
  String get previousMonth => 'আগের মাস';

  @override
  String get nextMonth => 'পরের মাস';

  @override
  String get budgetThisMonth => 'এই মাসের বাজেট';

  @override
  String get spent => 'খরচ হয়েছে';

  @override
  String get remaining => 'বাকি';

  @override
  String get dailyAllowance => 'দৈনিক সীমা';

  @override
  String perDay(String amount) {
    return 'দিনে $amount';
  }

  @override
  String get thisMonthOnly => 'শুধু এই মাসে';

  @override
  String get thisMonthOnlyHint => 'অন্য মাসে সাধারণ সীমাই থাকবে।';

  @override
  String usualLimit(String amount) {
    return 'সাধারণ সীমা: $amount';
  }

  @override
  String get useUsualLimit => 'সাধারণ সীমা ব্যবহার করুন';

  @override
  String get noTransactionsOnDay => 'এই দিনে কিছু লেখা নেই।';

  @override
  String get categories => 'খাতসমূহ';

  @override
  String get noCategories => 'এখনো কোনো খাত নেই।';

  @override
  String get renameCategory => 'খাতের নাম বদলান';

  @override
  String deleteCategoryConfirm(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countটি লেনদেন খাত ছাড়া থেকে যাবে, আর এর বাজেট মুছে যাবে।',
      zero: 'এর বাজেটও মুছে যাবে।',
    );
    return '\"$name\" মুছবেন? $_temp0';
  }

  @override
  String get net => 'নিট';

  @override
  String get lastSixMonths => 'গত ৬ মাস';

  @override
  String get topCategories => 'সবচেয়ে বেশি খরচ';

  @override
  String changeVsLastMonth(String percent) {
    return 'গত মাসের তুলনায় $percent%';
  }

  @override
  String get newThisMonth => 'এই মাসে নতুন';

  @override
  String get accountBalances => 'অ্যাকাউন্টের ব্যালেন্স';

  @override
  String get server => 'সার্ভার';

  @override
  String get serverHint =>
      'এই টেস্ট বিল্ড যে ক্যাশারু সার্ভারের সাথে কথা বলে তার ঠিকানা।';

  @override
  String get serverChangeConfirm =>
      'সার্ভার বদলাবেন? আপনি লগ আউট হবেন এবং এই ডিভাইসের তথ্য মুছে যাবে।';

  @override
  String get serverInvalid =>
      'http:// বা https:// দিয়ে শুরু হওয়া ঠিকানা লিখুন';

  @override
  String get resetToDefault => 'আগের অবস্থায় ফেরান';

  @override
  String version(String version) {
    return 'সংস্করণ $version';
  }

  @override
  String get sendFeedback => 'মতামত পাঠান';

  @override
  String get sendFeedbackHint => 'কী ভালো লাগছে আর কী লাগছে না, জানান।';

  @override
  String get needsConnectionRetry =>
      'এর জন্য ইন্টারনেট সংযোগ লাগবে। অনলাইনে এসে আবার চেষ্টা করুন।';

  @override
  String get retry => 'আবার চেষ্টা করুন';
}
