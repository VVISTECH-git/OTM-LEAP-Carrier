import 'app_localizations.dart';

// ignore_for_file: type=lint

/// French translations for LEAP Carrier.
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override String get appTitle => 'LEAP Carrier';
  @override String get poweredBy => 'Propulsé par Oracle OTM';
  @override String get signIn => 'Se connecter';
  @override String get username => 'Nom d\'utilisateur';
  @override String get password => 'Mot de passe';
  @override String get rememberMe => 'Se souvenir de moi';
  @override String get usernameRequired => 'Le nom d\'utilisateur est requis';
  @override String get passwordRequired => 'Le mot de passe est requis';
  @override String get invalidCredentials => 'Identifiants invalides. Vérifiez votre nom d\'utilisateur et mot de passe.';
  @override String serverError(int code) => 'Erreur serveur ($code). Réessayez ou contactez votre administrateur.';
  @override String attemptsRemaining(int count) => '$count tentative${count == 1 ? '' : 's'} restante${count == 1 ? '' : 's'} avant verrouillage';
  @override String tryAgainIn(int seconds) => 'Réessayez dans ${seconds}s';

  @override String get otmInstance => 'Instance OTM';
  @override String get swipeToRemove => 'Glisser à gauche pour supprimer';
  @override String get scanNewInstance => 'Scanner une nouvelle instance';
  @override String get savedInstances => 'Instances enregistrées';
  @override String get noInstancesSaved => 'Aucune instance enregistrée';
  @override String get tapToSetupInstance => 'Appuyez pour configurer l\'instance OTM';
  @override String get confirmInstance => 'Confirmer l\'instance';
  @override String get addOtmInstance => 'Ajouter une instance OTM';
  @override String get saveAndUse => 'Enregistrer et utiliser cette instance';
  @override String get scanAgain => 'Scanner à nouveau';
  @override String get scanQrCode => 'Scanner le code QR';
  @override String get enterManually => 'Saisir manuellement';
  @override String get pointCamera => 'Pointez la caméra vers le code QR de l\'instance OTM';
  @override String get urlValidating => 'L\'URL sera validée pendant la saisie';
  @override String get urlNotRecognised => 'URL non reconnue comme instance OTM';
  @override String get otmProduction => 'OTM Production';
  @override String get otmTest => 'OTM Test';
  @override String get otmDevelopment => 'OTM Développement';
  @override String otmDevelopmentN(int n) => 'OTM Développement $n';

  @override String get navHome => 'Accueil';
  @override String get navSpotBids => 'Offres spot';
  @override String get navTendered => 'Appels d\'offres';
  @override String get navActive => 'Actifs';
  @override String get navInvoicing => 'Facturation';

  @override String get accept => 'Accepter';
  @override String get decline => 'Décliner';
  @override String get reject => 'Rejeter';
  @override String get cancel => 'Annuler';
  @override String get retry => 'Réessayer';
  @override String get refresh => 'Actualiser';
  @override String get save => 'Enregistrer';
  @override String get submit => 'Soumettre';
  @override String get done => 'Terminé';
  @override String get edit => 'Modifier';
  @override String get search => 'Rechercher';
  @override String get signOut => 'Se déconnecter';
  @override String get signOutConfirm => 'Voulez-vous vraiment vous déconnecter ?';
  @override String get yes => 'Oui';
  @override String get no => 'Non';

  @override String get shipment => 'Expédition';
  @override String get shipmentId => 'ID expédition';
  @override String get weight => 'Poids';
  @override String get pickup => 'Enlèvement';
  @override String get delivery => 'Livraison';
  @override String get origin => 'Origine';
  @override String get destination => 'Destination';
  @override String get status => 'Statut';
  @override String get language => 'Langue';
  @override String get changeTheme => 'Changer le thème';

  @override String get homeTitle => 'LEAP Carrier';
  @override String get allShipments => 'Toutes les expéditions';
  @override String get noShipments => 'Aucune expédition';
  @override String get pullToRefresh => 'Tirer vers le bas pour actualiser';
  @override String get needsAttention => 'Attention requise';
  @override String activeShipments(int count) => '$count actives';
  @override String tenderedCount(int count) => '$count en attente';
  @override String spotBidsCount(int count) => '$count disponibles';

  @override String get tenderedTitle => 'Expéditions sous appel d\'offres';
  @override String get tenderPending => 'Offre en attente';
  @override String get tenderAccepted => 'Acceptée';
  @override String get tenderRejected => 'Rejetée';
  @override String get acceptTender => 'Accepter l\'offre';
  @override String get declineTender => 'Décliner l\'offre';
  @override String get confirmAccept => 'Oui, accepter';
  @override String get confirmDecline => 'Oui, rejeter';
  @override String get actionCannotBeUndone => 'Cette action est irréversible.';
  @override String get respondBy => 'Répondre avant';
  @override String get tenderApprovedSuccess => 'Offre acceptée avec succès !';
  @override String get tenderRejectedSuccess => 'Offre rejetée avec succès !';
  @override String get noTenderedShipments => 'Aucune expédition sous offre';
  @override String get noActionableTender => 'Aucune offre exploitable pour cette expédition.';
  @override String get driverNotAssigned => 'Conducteur non assigné';
  @override String get smsNotSent => 'SMS non envoyé';

  @override String get spotBidsTitle => 'Expéditions offres spot';
  @override String get placeBid => 'Faire une offre';
  @override String get submitBid => 'Soumettre l\'offre';
  @override String get buyItNow => 'Acheter maintenant';
  @override String get marketRate => 'Taux du marché';
  @override String get yourBidAmount => 'Montant de votre offre';
  @override String get bidSubmittedSuccess => 'Offre soumise avec succès !';
  @override String get noSpotBidShipments => 'Aucune expédition spot disponible';
  @override String get existingBidLabel => 'Votre offre actuelle';
  @override String get bidWon => 'Offre remportée';

  @override String get activeTitle => 'Expéditions actives';
  @override String get inTransit => 'En transit';
  @override String get atPickup => 'À l\'enlèvement';
  @override String get etaLabel => 'ETA';
  @override String get noActiveShipments => 'Aucune expédition active';
  @override String get stopTimeline => 'Chronologie des arrêts';
  @override String get addEvent => 'Ajouter un événement';
  @override String get trackEvents => 'Suivi des événements';
  @override String get noTrackingEvents => 'Aucun événement de suivi';
  @override String get noEventUpdate => 'Aucune mise à jour depuis';

  @override String get assignDriver => 'Assigner un conducteur';
  @override String get assignDriverTruck => 'Assigner conducteur et camion';
  @override String get driverName => 'Nom du conducteur';
  @override String get driverPhone => 'Téléphone du conducteur';
  @override String get vehicleReg => 'Immatriculation du véhicule';
  @override String get truckType => 'Type de camion';
  @override String get assignNow => 'Assigner maintenant';
  @override String get assignLater => 'Assigner plus tard';
  @override String get driverAssignedSuccess => 'Conducteur assigné avec succès !';
  @override String get enterDriverPhone => 'Veuillez saisir le numéro de téléphone du conducteur';

  @override String get invoicingTitle => 'Facturation';
  @override String get costs => 'Coûts';
  @override String get invoices => 'Factures';
  @override String get addCost => 'Ajouter un coût';
  @override String get generateInvoice => 'Générer une facture';
  @override String get costType => 'Type de coût';
  @override String get amount => 'Montant';
  @override String get description => 'Description';
  @override String get adjustmentReason => 'Motif de l\'ajustement';
  @override String get totalAmount => 'Total';
  @override String get invoiceHistoryComingSoon => 'Historique des factures bientôt disponible';
  @override String get costAddedSuccess => 'Coût ajouté avec succès !';
  @override String get enterValidAmount => 'Veuillez saisir un montant valide';

  @override String get truckLcv => 'VUL (Petit)';
  @override String get truck24ft => '24 pieds';
  @override String get truck32ft => '32 pieds';
  @override String get truck40ft => '40 pieds';
  @override String get truckTrailer => 'Semi-remorque';
}
