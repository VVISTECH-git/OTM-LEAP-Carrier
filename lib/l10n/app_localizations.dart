import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Usage: AppLocalizations.of(context).stringKey
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
    Locale('fr'),
    Locale('es'),
    Locale('pt'),
    Locale('pl'),
    Locale('hi'),
    Locale('de'),
  ];

  // ── App identity ───────────────────────────────────────────────────────────
  String get appTitle;
  String get poweredBy;

  // ── Login screen ───────────────────────────────────────────────────────────
  String get signIn;
  String get username;
  String get password;
  String get rememberMe;
  String get usernameRequired;
  String get passwordRequired;
  String get invalidCredentials;
  String serverError(int code);
  String attemptsRemaining(int count);
  String tryAgainIn(int seconds);

  // ── OTM instance picker ────────────────────────────────────────────────────
  String get otmInstance;
  String get swipeToRemove;
  String get scanNewInstance;
  String get savedInstances;
  String get noInstancesSaved;
  String get tapToSetupInstance;
  String get confirmInstance;
  String get addOtmInstance;
  String get saveAndUse;
  String get scanAgain;
  String get scanQrCode;
  String get enterManually;
  String get pointCamera;
  String get urlValidating;
  String get urlNotRecognised;
  String get otmProduction;
  String get otmTest;
  String get otmDevelopment;
  String otmDevelopmentN(int n);

  // ── Navigation ─────────────────────────────────────────────────────────────
  String get navHome;
  String get navSpotBids;
  String get navTendered;
  String get navActive;
  String get navInvoicing;

  // ── Common actions ─────────────────────────────────────────────────────────
  String get accept;
  String get decline;
  String get reject;
  String get cancel;
  String get retry;
  String get refresh;
  String get save;
  String get submit;
  String get done;
  String get edit;
  String get search;
  String get signOut;
  String get signOutConfirm;
  String get yes;
  String get no;

  // ── Common labels ──────────────────────────────────────────────────────────
  String get shipment;
  String get shipmentId;
  String get weight;
  String get pickup;
  String get delivery;
  String get origin;
  String get destination;
  String get status;
  String get language;
  String get changeTheme;

  // ── Home screen ────────────────────────────────────────────────────────────
  String get homeTitle;
  String get allShipments;
  String get noShipments;
  String get pullToRefresh;
  String get needsAttention;
  String activeShipments(int count);
  String tenderedCount(int count);
  String spotBidsCount(int count);

  // ── Tendered shipments ─────────────────────────────────────────────────────
  String get tenderedTitle;
  String get tenderPending;
  String get tenderAccepted;
  String get tenderRejected;
  String get acceptTender;
  String get declineTender;
  String get confirmAccept;
  String get confirmDecline;
  String get actionCannotBeUndone;
  String get respondBy;
  String get tenderApprovedSuccess;
  String get tenderRejectedSuccess;
  String get noTenderedShipments;
  String get noActionableTender;
  String get driverNotAssigned;
  String get smsNotSent;

  // ── Spot bids ──────────────────────────────────────────────────────────────
  String get spotBidsTitle;
  String get placeBid;
  String get submitBid;
  String get buyItNow;
  String get marketRate;
  String get yourBidAmount;
  String get bidSubmittedSuccess;
  String get noSpotBidShipments;
  String get existingBidLabel;
  String get bidWon;

  // ── Active shipments ───────────────────────────────────────────────────────
  String get activeTitle;
  String get inTransit;
  String get atPickup;
  String get etaLabel;
  String get noActiveShipments;
  String get stopTimeline;
  String get addEvent;
  String get trackEvents;
  String get noTrackingEvents;
  String get noEventUpdate;

  // ── Driver assignment ──────────────────────────────────────────────────────
  String get assignDriver;
  String get assignDriverTruck;
  String get driverName;
  String get driverPhone;
  String get vehicleReg;
  String get truckType;
  String get assignNow;
  String get assignLater;
  String get driverAssignedSuccess;
  String get enterDriverPhone;

  // ── Invoicing ──────────────────────────────────────────────────────────────
  String get invoicingTitle;
  String get costs;
  String get invoices;
  String get addCost;
  String get generateInvoice;
  String get costType;
  String get amount;
  String get description;
  String get adjustmentReason;
  String get totalAmount;
  String get invoiceHistoryComingSoon;
  String get costAddedSuccess;
  String get enterValidAmount;

  // ── Truck types ────────────────────────────────────────────────────────────
  String get truckLcv;
  String get truck24ft;
  String get truck32ft;
  String get truck40ft;
  String get truckTrailer;
}

// ── Delegate ───────────────────────────────────────────────────────────────────

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(
        lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar', 'de', 'en', 'es', 'fr', 'hi', 'pl', 'pt'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'fr': return AppLocalizationsFr();
    case 'hi': return AppLocalizationsHi();
    case 'pl': return AppLocalizationsPl();
    case 'pt': return AppLocalizationsPt();
  }
  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale".',
  );
}
