import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Tradee'**
  String get appTitle;

  /// No description provided for @marketsTitle.
  ///
  /// In en, this message translates to:
  /// **'Markets'**
  String get marketsTitle;

  /// No description provided for @portfolioTitle.
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get portfolioTitle;

  /// No description provided for @strategyBuilderTitle.
  ///
  /// In en, this message translates to:
  /// **'Strategy Builder'**
  String get strategyBuilderTitle;

  /// No description provided for @riskTitle.
  ///
  /// In en, this message translates to:
  /// **'Risk Management'**
  String get riskTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @tabPositions.
  ///
  /// In en, this message translates to:
  /// **'Positions'**
  String get tabPositions;

  /// No description provided for @tabHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get tabHistory;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @reconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting...'**
  String get reconnecting;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// No description provided for @noPositions.
  ///
  /// In en, this message translates to:
  /// **'No active positions'**
  String get noPositions;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No trade history yet'**
  String get noHistory;

  /// No description provided for @buildStrategies.
  ///
  /// In en, this message translates to:
  /// **'Build Multi-leg Strategies'**
  String get buildStrategies;

  /// No description provided for @buy.
  ///
  /// In en, this message translates to:
  /// **'BUY'**
  String get buy;

  /// No description provided for @sell.
  ///
  /// In en, this message translates to:
  /// **'SELL'**
  String get sell;

  /// No description provided for @buyLong.
  ///
  /// In en, this message translates to:
  /// **'BUY / LONG'**
  String get buyLong;

  /// No description provided for @sellShort.
  ///
  /// In en, this message translates to:
  /// **'SELL / SHORT'**
  String get sellShort;

  /// No description provided for @closePosition.
  ///
  /// In en, this message translates to:
  /// **'CLOSE POSITION'**
  String get closePosition;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'CANCEL ORDER'**
  String get cancelOrder;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get cancel;

  /// No description provided for @marketOrder.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get marketOrder;

  /// No description provided for @limitOrder.
  ///
  /// In en, this message translates to:
  /// **'Limit'**
  String get limitOrder;

  /// No description provided for @limitPrice.
  ///
  /// In en, this message translates to:
  /// **'Limit Price'**
  String get limitPrice;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @contracts.
  ///
  /// In en, this message translates to:
  /// **'Contracts'**
  String get contracts;

  /// No description provided for @bid.
  ///
  /// In en, this message translates to:
  /// **'Bid'**
  String get bid;

  /// No description provided for @ask.
  ///
  /// In en, this message translates to:
  /// **'Ask'**
  String get ask;

  /// No description provided for @spread.
  ///
  /// In en, this message translates to:
  /// **'Spread'**
  String get spread;

  /// No description provided for @iv.
  ///
  /// In en, this message translates to:
  /// **'IV'**
  String get iv;

  /// No description provided for @estMargin.
  ///
  /// In en, this message translates to:
  /// **'Est. Margin'**
  String get estMargin;

  /// No description provided for @equity.
  ///
  /// In en, this message translates to:
  /// **'Equity'**
  String get equity;

  /// No description provided for @usedMargin.
  ///
  /// In en, this message translates to:
  /// **'Used Margin'**
  String get usedMargin;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @unrealized.
  ///
  /// In en, this message translates to:
  /// **'Unrealized'**
  String get unrealized;

  /// No description provided for @realized.
  ///
  /// In en, this message translates to:
  /// **'Realized'**
  String get realized;

  /// No description provided for @netDelta.
  ///
  /// In en, this message translates to:
  /// **'Net Delta (Δ)'**
  String get netDelta;

  /// No description provided for @netGamma.
  ///
  /// In en, this message translates to:
  /// **'Net Gamma (Γ)'**
  String get netGamma;

  /// No description provided for @netVega.
  ///
  /// In en, this message translates to:
  /// **'Net Vega (ν)'**
  String get netVega;

  /// No description provided for @netTheta.
  ///
  /// In en, this message translates to:
  /// **'Net Theta (Θ)'**
  String get netTheta;

  /// No description provided for @priceSensitivity.
  ///
  /// In en, this message translates to:
  /// **'Price sensitivity per \$1 move'**
  String get priceSensitivity;

  /// No description provided for @deltaChangeRate.
  ///
  /// In en, this message translates to:
  /// **'Delta change rate'**
  String get deltaChangeRate;

  /// No description provided for @volSensitivity.
  ///
  /// In en, this message translates to:
  /// **'Sensitivity to 1% vol change'**
  String get volSensitivity;

  /// No description provided for @timeDecay.
  ///
  /// In en, this message translates to:
  /// **'Time decay per day'**
  String get timeDecay;

  /// No description provided for @stressTest.
  ///
  /// In en, this message translates to:
  /// **'Stress Test'**
  String get stressTest;

  /// No description provided for @spotMove.
  ///
  /// In en, this message translates to:
  /// **'Spot Move: {shift}%'**
  String spotMove(String shift);

  /// No description provided for @pnlLabel.
  ///
  /// In en, this message translates to:
  /// **'P&L: {pnl}'**
  String pnlLabel(String pnl);

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @marginUtilization.
  ///
  /// In en, this message translates to:
  /// **'Margin Utilization'**
  String get marginUtilization;

  /// No description provided for @liquidationWarning.
  ///
  /// In en, this message translates to:
  /// **'LIQUIDATION TRIGGERED: Positions force-closed at market'**
  String get liquidationWarning;

  /// No description provided for @liquidationSnackbar.
  ///
  /// In en, this message translates to:
  /// **'LIQUIDATION: All positions force-closed at market'**
  String get liquidationSnackbar;

  /// No description provided for @expirySnackbar.
  ///
  /// In en, this message translates to:
  /// **'EXPIRY: All positions settled at intrinsic value'**
  String get expirySnackbar;

  /// No description provided for @resetAccount.
  ///
  /// In en, this message translates to:
  /// **'Reset Demo Account'**
  String get resetAccount;

  /// No description provided for @resetAccountDesc.
  ///
  /// In en, this message translates to:
  /// **'Wipe all positions and reset balance to \$100,000'**
  String get resetAccountDesc;

  /// No description provided for @resetConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Account?'**
  String get resetConfirmTitle;

  /// No description provided for @resetConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This will delete all positions, history, and reset balance.'**
  String get resetConfirmBody;

  /// No description provided for @resetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account Reset Successful'**
  String get resetSuccess;

  /// No description provided for @volatility.
  ///
  /// In en, this message translates to:
  /// **'VOLATILITY'**
  String get volatility;

  /// No description provided for @rollingVolLabel.
  ///
  /// In en, this message translates to:
  /// **'Rolling Realized Vol (1h window)'**
  String get rollingVolLabel;

  /// No description provided for @rollingVolDesc.
  ///
  /// In en, this message translates to:
  /// **'Calculated from live price data'**
  String get rollingVolDesc;

  /// No description provided for @fixedVolLabel.
  ///
  /// In en, this message translates to:
  /// **'Fixed 50% IV'**
  String get fixedVolLabel;

  /// No description provided for @fixedVolDesc.
  ///
  /// In en, this message translates to:
  /// **'Constant implied volatility for all strikes'**
  String get fixedVolDesc;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'ABOUT'**
  String get about;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Tradee'**
  String get appName;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Crypto Daily Options Simulator'**
  String get appSubtitle;

  /// No description provided for @pricingModel.
  ///
  /// In en, this message translates to:
  /// **'Pricing Model'**
  String get pricingModel;

  /// No description provided for @pricingModelValue.
  ///
  /// In en, this message translates to:
  /// **'Black-Scholes (European)'**
  String get pricingModelValue;

  /// No description provided for @expiry.
  ///
  /// In en, this message translates to:
  /// **'Expiry'**
  String get expiry;

  /// No description provided for @expiryValue.
  ///
  /// In en, this message translates to:
  /// **'Daily 05:29:59 IST'**
  String get expiryValue;

  /// No description provided for @addLeg.
  ///
  /// In en, this message translates to:
  /// **'ADD LEG'**
  String get addLeg;

  /// No description provided for @totalCostCredit.
  ///
  /// In en, this message translates to:
  /// **'Total Cost/Credit'**
  String get totalCostCredit;

  /// No description provided for @maxProfit.
  ///
  /// In en, this message translates to:
  /// **'Max Profit: '**
  String get maxProfit;

  /// No description provided for @maxLoss.
  ///
  /// In en, this message translates to:
  /// **'Max Loss: '**
  String get maxLoss;

  /// No description provided for @calls.
  ///
  /// In en, this message translates to:
  /// **'CALLS'**
  String get calls;

  /// No description provided for @puts.
  ///
  /// In en, this message translates to:
  /// **'PUTS'**
  String get puts;

  /// No description provided for @strike.
  ///
  /// In en, this message translates to:
  /// **'STRIKE'**
  String get strike;

  /// No description provided for @atm.
  ///
  /// In en, this message translates to:
  /// **'ATM'**
  String get atm;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get pending;

  /// No description provided for @longLabel.
  ///
  /// In en, this message translates to:
  /// **'LONG'**
  String get longLabel;

  /// No description provided for @shortLabel.
  ///
  /// In en, this message translates to:
  /// **'SHORT'**
  String get shortLabel;

  /// No description provided for @failedToLoadChain.
  ///
  /// In en, this message translates to:
  /// **'Failed to load chain'**
  String get failedToLoadChain;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;
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
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
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
