import 'app_localizations.dart';

// ignore_for_file: type=lint

/// Polish translations for LEAP Carrier.
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override String get appTitle => 'LEAP Carrier';
  @override String get poweredBy => 'Zasilane przez Oracle OTM';
  @override String get signIn => 'Zaloguj się';
  @override String get username => 'Nazwa użytkownika';
  @override String get password => 'Hasło';
  @override String get rememberMe => 'Zapamiętaj mnie';
  @override String get usernameRequired => 'Nazwa użytkownika jest wymagana';
  @override String get passwordRequired => 'Hasło jest wymagane';
  @override String get invalidCredentials => 'Nieprawidłowe dane. Sprawdź nazwę użytkownika i hasło.';
  @override String serverError(int code) => 'Błąd serwera ($code). Spróbuj ponownie lub skontaktuj się z administratorem.';
  @override String attemptsRemaining(int count) => 'Pozostało $count prób${count == 1 ? 'a' : ''} przed blokadą';
  @override String tryAgainIn(int seconds) => 'Spróbuj ponownie za ${seconds}s';

  @override String get otmInstance => 'Instancja OTM';
  @override String get swipeToRemove => 'Przesuń w lewo, aby usunąć';
  @override String get scanNewInstance => 'Skanuj nową instancję';
  @override String get savedInstances => 'Zapisane instancje';
  @override String get noInstancesSaved => 'Brak zapisanych instancji';
  @override String get tapToSetupInstance => 'Dotknij, aby skonfigurować instancję OTM';
  @override String get confirmInstance => 'Potwierdź instancję';
  @override String get addOtmInstance => 'Dodaj instancję OTM';
  @override String get saveAndUse => 'Zapisz i użyj tej instancji';
  @override String get scanAgain => 'Skanuj ponownie';
  @override String get scanQrCode => 'Skanuj kod QR';
  @override String get enterManually => 'Wprowadź ręcznie';
  @override String get pointCamera => 'Skieruj kamerę na kod QR instancji OTM';
  @override String get urlValidating => 'URL będzie weryfikowany podczas pisania';
  @override String get urlNotRecognised => 'URL nie jest rozpoznany jako instancja OTM';
  @override String get otmProduction => 'OTM Produkcja';
  @override String get otmTest => 'OTM Test';
  @override String get otmDevelopment => 'OTM Rozwój';
  @override String otmDevelopmentN(int n) => 'OTM Rozwój $n';

  @override String get navHome => 'Główna';
  @override String get navSpotBids => 'Oferty spot';
  @override String get navTendered => 'Przetargi';
  @override String get navActive => 'Aktywne';
  @override String get navInvoicing => 'Faktury';

  @override String get accept => 'Akceptuj';
  @override String get decline => 'Odrzuć';
  @override String get reject => 'Odrzuć';
  @override String get cancel => 'Anuluj';
  @override String get retry => 'Spróbuj ponownie';
  @override String get refresh => 'Odśwież';
  @override String get save => 'Zapisz';
  @override String get submit => 'Wyślij';
  @override String get done => 'Gotowe';
  @override String get edit => 'Edytuj';
  @override String get search => 'Szukaj';
  @override String get signOut => 'Wyloguj się';
  @override String get signOutConfirm => 'Czy na pewno chcesz się wylogować?';
  @override String get yes => 'Tak';
  @override String get no => 'Nie';

  @override String get shipment => 'Przesyłka';
  @override String get shipmentId => 'ID przesyłki';
  @override String get weight => 'Waga';
  @override String get pickup => 'Odbiór';
  @override String get delivery => 'Dostawa';
  @override String get origin => 'Nadawca';
  @override String get destination => 'Odbiorca';
  @override String get status => 'Status';
  @override String get language => 'Język';
  @override String get changeTheme => 'Zmień motyw';

  @override String get homeTitle => 'LEAP Carrier';
  @override String get allShipments => 'Wszystkie przesyłki';
  @override String get noShipments => 'Brak przesyłek';
  @override String get pullToRefresh => 'Przeciągnij w dół, aby odświeżyć';
  @override String get needsAttention => 'Wymaga uwagi';
  @override String activeShipments(int count) => '$count aktywne';
  @override String tenderedCount(int count) => '$count oczekujące';
  @override String spotBidsCount(int count) => '$count dostępne';

  @override String get tenderedTitle => 'Przesyłki przetargowe';
  @override String get tenderPending => 'Przetarg oczekujący';
  @override String get tenderAccepted => 'Zaakceptowany';
  @override String get tenderRejected => 'Odrzucony';
  @override String get acceptTender => 'Akceptuj przetarg';
  @override String get declineTender => 'Odrzuć przetarg';
  @override String get confirmAccept => 'Tak, akceptuj';
  @override String get confirmDecline => 'Tak, odrzuć';
  @override String get actionCannotBeUndone => 'Tej akcji nie można cofnąć.';
  @override String get respondBy => 'Odpowiedz do';
  @override String get tenderApprovedSuccess => 'Przetarg zaakceptowany pomyślnie!';
  @override String get tenderRejectedSuccess => 'Przetarg odrzucony pomyślnie!';
  @override String get noTenderedShipments => 'Brak przesyłek przetargowych';
  @override String get noActionableTender => 'Nie znaleziono przetargu do realizacji dla tej przesyłki.';
  @override String get driverNotAssigned => 'Kierowca nieprzypisany';
  @override String get smsNotSent => 'SMS nie wysłany';

  @override String get spotBidsTitle => 'Przesyłki oferty spot';
  @override String get placeBid => 'Złóż ofertę';
  @override String get submitBid => 'Wyślij ofertę';
  @override String get buyItNow => 'Kup teraz';
  @override String get marketRate => 'Stawka rynkowa';
  @override String get yourBidAmount => 'Kwota Twojej oferty';
  @override String get bidSubmittedSuccess => 'Oferta wysłana pomyślnie!';
  @override String get noSpotBidShipments => 'Brak przesyłek spot';
  @override String get existingBidLabel => 'Twoja obecna oferta';
  @override String get bidWon => 'Oferta wygrała';

  @override String get activeTitle => 'Aktywne przesyłki';
  @override String get inTransit => 'W transporcie';
  @override String get atPickup => 'Przy odbiorze';
  @override String get etaLabel => 'ETA';
  @override String get noActiveShipments => 'Brak aktywnych przesyłek';
  @override String get stopTimeline => 'Harmonogram postojów';
  @override String get addEvent => 'Dodaj zdarzenie';
  @override String get trackEvents => 'Śledź zdarzenia';
  @override String get noTrackingEvents => 'Brak zdarzeń śledzenia';
  @override String get noEventUpdate => 'Brak aktualizacji od';

  @override String get assignDriver => 'Przypisz kierowcę';
  @override String get assignDriverTruck => 'Przypisz kierowcę i ciężarówkę';
  @override String get driverName => 'Imię kierowcy';
  @override String get driverPhone => 'Telefon kierowcy';
  @override String get vehicleReg => 'Numer rejestracyjny pojazdu';
  @override String get truckType => 'Typ ciężarówki';
  @override String get assignNow => 'Przypisz teraz';
  @override String get assignLater => 'Przypisz później';
  @override String get driverAssignedSuccess => 'Kierowca przypisany pomyślnie!';
  @override String get enterDriverPhone => 'Podaj numer telefonu kierowcy';

  @override String get invoicingTitle => 'Faktury';
  @override String get costs => 'Koszty';
  @override String get invoices => 'Faktury';
  @override String get addCost => 'Dodaj koszt';
  @override String get generateInvoice => 'Generuj fakturę';
  @override String get costType => 'Typ kosztu';
  @override String get amount => 'Kwota';
  @override String get description => 'Opis';
  @override String get adjustmentReason => 'Powód korekty';
  @override String get totalAmount => 'Łącznie';
  @override String get invoiceHistoryComingSoon => 'Historia faktur wkrótce';
  @override String get costAddedSuccess => 'Koszt dodany pomyślnie!';
  @override String get enterValidAmount => 'Podaj prawidłową kwotę';

  @override String get truckLcv => 'LCV (Mały)';
  @override String get truck24ft => '24 stopy';
  @override String get truck32ft => '32 stopy';
  @override String get truck40ft => '40 stóp';
  @override String get truckTrailer => 'Naczepa';
}
