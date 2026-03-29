import 'app_localizations.dart';

// ignore_for_file: type=lint

/// Spanish translations for LEAP Carrier.
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override String get appTitle => 'LEAP Carrier';
  @override String get poweredBy => 'Impulsado por Oracle OTM';
  @override String get signIn => 'Iniciar sesión';
  @override String get username => 'Usuario';
  @override String get password => 'Contraseña';
  @override String get rememberMe => 'Recordarme';
  @override String get usernameRequired => 'El usuario es obligatorio';
  @override String get passwordRequired => 'La contraseña es obligatoria';
  @override String get invalidCredentials => 'Credenciales inválidas. Verifica tu usuario y contraseña.';
  @override String serverError(int code) => 'Error del servidor ($code). Intenta de nuevo o contacta a tu administrador.';
  @override String attemptsRemaining(int count) => '$count intento${count == 1 ? '' : 's'} restante${count == 1 ? '' : 's'} antes del bloqueo';
  @override String tryAgainIn(int seconds) => 'Intenta de nuevo en ${seconds}s';

  @override String get otmInstance => 'Instancia OTM';
  @override String get swipeToRemove => 'Desliza a la izquierda para eliminar';
  @override String get scanNewInstance => 'Escanear nueva instancia';
  @override String get savedInstances => 'Instancias guardadas';
  @override String get noInstancesSaved => 'No hay instancias guardadas';
  @override String get tapToSetupInstance => 'Toca para configurar la instancia OTM';
  @override String get confirmInstance => 'Confirmar instancia';
  @override String get addOtmInstance => 'Agregar instancia OTM';
  @override String get saveAndUse => 'Guardar y usar esta instancia';
  @override String get scanAgain => 'Escanear de nuevo';
  @override String get scanQrCode => 'Escanear código QR';
  @override String get enterManually => 'Ingresar manualmente';
  @override String get pointCamera => 'Apunta la cámara al código QR de la instancia OTM';
  @override String get urlValidating => 'La URL se validará mientras escribes';
  @override String get urlNotRecognised => 'URL no reconocida como instancia OTM';
  @override String get otmProduction => 'OTM Producción';
  @override String get otmTest => 'OTM Pruebas';
  @override String get otmDevelopment => 'OTM Desarrollo';
  @override String otmDevelopmentN(int n) => 'OTM Desarrollo $n';

  @override String get navHome => 'Inicio';
  @override String get navSpotBids => 'Ofertas spot';
  @override String get navTendered => 'Licitaciones';
  @override String get navActive => 'Activos';
  @override String get navInvoicing => 'Facturación';

  @override String get accept => 'Aceptar';
  @override String get decline => 'Rechazar';
  @override String get reject => 'Rechazar';
  @override String get cancel => 'Cancelar';
  @override String get retry => 'Reintentar';
  @override String get refresh => 'Actualizar';
  @override String get save => 'Guardar';
  @override String get submit => 'Enviar';
  @override String get done => 'Listo';
  @override String get edit => 'Editar';
  @override String get search => 'Buscar';
  @override String get signOut => 'Cerrar sesión';
  @override String get signOutConfirm => '¿Seguro que deseas cerrar sesión?';
  @override String get yes => 'Sí';
  @override String get no => 'No';

  @override String get shipment => 'Envío';
  @override String get shipmentId => 'ID de envío';
  @override String get weight => 'Peso';
  @override String get pickup => 'Recogida';
  @override String get delivery => 'Entrega';
  @override String get origin => 'Origen';
  @override String get destination => 'Destino';
  @override String get status => 'Estado';
  @override String get language => 'Idioma';
  @override String get changeTheme => 'Cambiar tema';

  @override String get homeTitle => 'LEAP Carrier';
  @override String get allShipments => 'Todos los envíos';
  @override String get noShipments => 'Sin envíos';
  @override String get pullToRefresh => 'Desliza hacia abajo para actualizar';
  @override String get needsAttention => 'Requiere atención';
  @override String activeShipments(int count) => '$count activos';
  @override String tenderedCount(int count) => '$count pendientes';
  @override String spotBidsCount(int count) => '$count disponibles';

  @override String get tenderedTitle => 'Envíos licitados';
  @override String get tenderPending => 'Licitación pendiente';
  @override String get tenderAccepted => 'Aceptado';
  @override String get tenderRejected => 'Rechazado';
  @override String get acceptTender => 'Aceptar licitación';
  @override String get declineTender => 'Rechazar licitación';
  @override String get confirmAccept => 'Sí, aceptar';
  @override String get confirmDecline => 'Sí, rechazar';
  @override String get actionCannotBeUndone => 'Esta acción no se puede deshacer.';
  @override String get respondBy => 'Responder antes de';
  @override String get tenderApprovedSuccess => '¡Licitación aprobada con éxito!';
  @override String get tenderRejectedSuccess => '¡Licitación rechazada con éxito!';
  @override String get noTenderedShipments => 'No hay envíos licitados';
  @override String get noActionableTender => 'No se encontró licitación accionable para este envío.';
  @override String get driverNotAssigned => 'Conductor no asignado';
  @override String get smsNotSent => 'SMS no enviado';

  @override String get spotBidsTitle => 'Ofertas spot';
  @override String get placeBid => 'Hacer oferta';
  @override String get submitBid => 'Enviar oferta';
  @override String get buyItNow => 'Comprar ahora';
  @override String get marketRate => 'Tarifa de mercado';
  @override String get yourBidAmount => 'Monto de tu oferta';
  @override String get bidSubmittedSuccess => '¡Oferta enviada con éxito!';
  @override String get noSpotBidShipments => 'No hay envíos spot disponibles';
  @override String get existingBidLabel => 'Tu oferta actual';
  @override String get bidWon => 'Oferta ganada';

  @override String get activeTitle => 'Envíos activos';
  @override String get inTransit => 'En tránsito';
  @override String get atPickup => 'En recogida';
  @override String get etaLabel => 'ETA';
  @override String get noActiveShipments => 'No hay envíos activos';
  @override String get stopTimeline => 'Cronología de paradas';
  @override String get addEvent => 'Agregar evento';
  @override String get trackEvents => 'Rastrear eventos';
  @override String get noTrackingEvents => 'Sin eventos de rastreo';
  @override String get noEventUpdate => 'Sin actualización desde hace';

  @override String get assignDriver => 'Asignar conductor';
  @override String get assignDriverTruck => 'Asignar conductor y camión';
  @override String get driverName => 'Nombre del conductor';
  @override String get driverPhone => 'Teléfono del conductor';
  @override String get vehicleReg => 'Número de matrícula';
  @override String get truckType => 'Tipo de camión';
  @override String get assignNow => 'Asignar ahora';
  @override String get assignLater => 'Asignar después';
  @override String get driverAssignedSuccess => '¡Conductor asignado con éxito!';
  @override String get enterDriverPhone => 'Por favor ingresa el teléfono del conductor';

  @override String get invoicingTitle => 'Facturación';
  @override String get costs => 'Costos';
  @override String get invoices => 'Facturas';
  @override String get addCost => 'Agregar costo';
  @override String get generateInvoice => 'Generar factura';
  @override String get costType => 'Tipo de costo';
  @override String get amount => 'Monto';
  @override String get description => 'Descripción';
  @override String get adjustmentReason => 'Motivo del ajuste';
  @override String get totalAmount => 'Total';
  @override String get invoiceHistoryComingSoon => 'Historial de facturas próximamente';
  @override String get costAddedSuccess => '¡Costo agregado con éxito!';
  @override String get enterValidAmount => 'Por favor ingresa un monto válido';

  @override String get truckLcv => 'LCV (Pequeño)';
  @override String get truck24ft => '24 pies';
  @override String get truck32ft => '32 pies';
  @override String get truck40ft => '40 pies';
  @override String get truckTrailer => 'Remolque';
}
