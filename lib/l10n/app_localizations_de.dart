import 'app_localizations.dart';

// ignore_for_file: type=lint

/// German translations for LEAP Carrier.
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override String get appTitle => 'LEAP Carrier';
  @override String get poweredBy => 'Unterstützt von Oracle OTM';
  @override String get signIn => 'Anmelden';
  @override String get username => 'Benutzername';
  @override String get password => 'Passwort';
  @override String get rememberMe => 'Angemeldet bleiben';
  @override String get usernameRequired => 'Benutzername ist erforderlich';
  @override String get passwordRequired => 'Passwort ist erforderlich';
  @override String get invalidCredentials => 'Ungültige Anmeldedaten. Überprüfen Sie Benutzername und Passwort.';
  @override String serverError(int code) => 'Serverfehler ($code). Bitte erneut versuchen oder Administrator kontaktieren.';
  @override String attemptsRemaining(int count) => 'Noch $count Versuch${count == 1 ? '' : 'e'} bis zur Sperrung';
  @override String tryAgainIn(int seconds) => 'Erneut versuchen in ${seconds}s';

  @override String get otmInstance => 'OTM-Instanz';
  @override String get swipeToRemove => 'Nach links wischen zum Entfernen';
  @override String get scanNewInstance => 'Neue Instanz scannen';
  @override String get savedInstances => 'Gespeicherte Instanzen';
  @override String get noInstancesSaved => 'Keine gespeicherten Instanzen';
  @override String get tapToSetupInstance => 'Tippen Sie, um die OTM-Instanz einzurichten';
  @override String get confirmInstance => 'Instanz bestätigen';
  @override String get addOtmInstance => 'OTM-Instanz hinzufügen';
  @override String get saveAndUse => 'Diese Instanz speichern und verwenden';
  @override String get scanAgain => 'Erneut scannen';
  @override String get scanQrCode => 'QR-Code scannen';
  @override String get enterManually => 'Manuell eingeben';
  @override String get pointCamera => 'Kamera auf den QR-Code der OTM-Instanz richten';
  @override String get urlValidating => 'URL wird während der Eingabe validiert';
  @override String get urlNotRecognised => 'URL nicht als OTM-Instanz erkannt';
  @override String get otmProduction => 'OTM Produktion';
  @override String get otmTest => 'OTM Test';
  @override String get otmDevelopment => 'OTM Entwicklung';
  @override String otmDevelopmentN(int n) => 'OTM Entwicklung $n';

  @override String get navHome => 'Startseite';
  @override String get navSpotBids => 'Spot-Angebote';
  @override String get navTendered => 'Ausschreibungen';
  @override String get navActive => 'Aktiv';
  @override String get navInvoicing => 'Abrechnung';

  @override String get accept => 'Akzeptieren';
  @override String get decline => 'Ablehnen';
  @override String get reject => 'Ablehnen';
  @override String get cancel => 'Abbrechen';
  @override String get retry => 'Erneut versuchen';
  @override String get refresh => 'Aktualisieren';
  @override String get save => 'Speichern';
  @override String get submit => 'Einreichen';
  @override String get done => 'Fertig';
  @override String get edit => 'Bearbeiten';
  @override String get search => 'Suchen';
  @override String get signOut => 'Abmelden';
  @override String get signOutConfirm => 'Möchten Sie sich wirklich abmelden?';
  @override String get yes => 'Ja';
  @override String get no => 'Nein';

  @override String get shipment => 'Sendung';
  @override String get shipmentId => 'Sendungs-ID';
  @override String get weight => 'Gewicht';
  @override String get pickup => 'Abholung';
  @override String get delivery => 'Lieferung';
  @override String get origin => 'Herkunft';
  @override String get destination => 'Ziel';
  @override String get status => 'Status';
  @override String get language => 'Sprache';
  @override String get changeTheme => 'Thema ändern';

  @override String get homeTitle => 'LEAP Carrier';
  @override String get allShipments => 'Alle Sendungen';
  @override String get noShipments => 'Keine Sendungen';
  @override String get pullToRefresh => 'Nach unten ziehen zum Aktualisieren';
  @override String get needsAttention => 'Handlungsbedarf';
  @override String activeShipments(int count) => '$count aktiv';
  @override String tenderedCount(int count) => '$count ausstehend';
  @override String spotBidsCount(int count) => '$count verfügbar';

  @override String get tenderedTitle => 'Ausgeschriebene Sendungen';
  @override String get tenderPending => 'Ausschreibung ausstehend';
  @override String get tenderAccepted => 'Akzeptiert';
  @override String get tenderRejected => 'Abgelehnt';
  @override String get acceptTender => 'Ausschreibung akzeptieren';
  @override String get declineTender => 'Ausschreibung ablehnen';
  @override String get confirmAccept => 'Ja, akzeptieren';
  @override String get confirmDecline => 'Ja, ablehnen';
  @override String get actionCannotBeUndone => 'Diese Aktion kann nicht rückgängig gemacht werden.';
  @override String get respondBy => 'Antworten bis';
  @override String get tenderApprovedSuccess => 'Ausschreibung erfolgreich akzeptiert!';
  @override String get tenderRejectedSuccess => 'Ausschreibung erfolgreich abgelehnt!';
  @override String get noTenderedShipments => 'Keine ausgeschriebenen Sendungen';
  @override String get noActionableTender => 'Kein bearbeitbares Angebot für diese Sendung gefunden.';
  @override String get driverNotAssigned => 'Kein Fahrer zugewiesen';
  @override String get smsNotSent => 'SMS nicht gesendet';

  @override String get spotBidsTitle => 'Spot-Angebote Sendungen';
  @override String get placeBid => 'Angebot abgeben';
  @override String get submitBid => 'Angebot einreichen';
  @override String get buyItNow => 'Sofort kaufen';
  @override String get marketRate => 'Marktpreis';
  @override String get yourBidAmount => 'Ihr Angebotsbetrag';
  @override String get bidSubmittedSuccess => 'Angebot erfolgreich eingereicht!';
  @override String get noSpotBidShipments => 'Keine Spot-Angebot-Sendungen';
  @override String get existingBidLabel => 'Ihr aktuelles Angebot';
  @override String get bidWon => 'Angebot gewonnen';

  @override String get activeTitle => 'Aktive Sendungen';
  @override String get inTransit => 'In Transit';
  @override String get atPickup => 'Bei Abholung';
  @override String get etaLabel => 'ETA';
  @override String get noActiveShipments => 'Keine aktiven Sendungen';
  @override String get stopTimeline => 'Haltezeitplan';
  @override String get addEvent => 'Ereignis hinzufügen';
  @override String get trackEvents => 'Ereignisse verfolgen';
  @override String get noTrackingEvents => 'Keine Tracking-Ereignisse';
  @override String get noEventUpdate => 'Kein Update seit';

  @override String get assignDriver => 'Fahrer zuweisen';
  @override String get assignDriverTruck => 'Fahrer und LKW zuweisen';
  @override String get driverName => 'Name des Fahrers';
  @override String get driverPhone => 'Telefonnummer des Fahrers';
  @override String get vehicleReg => 'Fahrzeugkennzeichen';
  @override String get truckType => 'LKW-Typ';
  @override String get assignNow => 'Jetzt zuweisen';
  @override String get assignLater => 'Später zuweisen';
  @override String get driverAssignedSuccess => 'Fahrer erfolgreich zugewiesen!';
  @override String get enterDriverPhone => 'Bitte geben Sie die Telefonnummer des Fahrers ein';

  @override String get invoicingTitle => 'Abrechnung';
  @override String get costs => 'Kosten';
  @override String get invoices => 'Rechnungen';
  @override String get addCost => 'Kosten hinzufügen';
  @override String get generateInvoice => 'Rechnung erstellen';
  @override String get costType => 'Kostenart';
  @override String get amount => 'Betrag';
  @override String get description => 'Beschreibung';
  @override String get adjustmentReason => 'Anpassungsgrund';
  @override String get totalAmount => 'Gesamt';
  @override String get invoiceHistoryComingSoon => 'Rechnungshistorie demnächst verfügbar';
  @override String get costAddedSuccess => 'Kosten erfolgreich hinzugefügt!';
  @override String get enterValidAmount => 'Bitte geben Sie einen gültigen Betrag ein';

  @override String get truckLcv => 'LCV (Klein)';
  @override String get truck24ft => '24 Fuß';
  @override String get truck32ft => '32 Fuß';
  @override String get truck40ft => '40 Fuß';
  @override String get truckTrailer => 'Sattelzug';
}
