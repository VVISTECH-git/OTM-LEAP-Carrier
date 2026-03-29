import 'app_localizations.dart';

// ignore_for_file: type=lint

/// Portuguese translations for LEAP Carrier.
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override String get appTitle => 'LEAP Carrier';
  @override String get poweredBy => 'Desenvolvido com Oracle OTM';
  @override String get signIn => 'Entrar';
  @override String get username => 'Usuário';
  @override String get password => 'Senha';
  @override String get rememberMe => 'Lembrar de mim';
  @override String get usernameRequired => 'O usuário é obrigatório';
  @override String get passwordRequired => 'A senha é obrigatória';
  @override String get invalidCredentials => 'Credenciais inválidas. Verifique seu usuário e senha.';
  @override String serverError(int code) => 'Erro do servidor ($code). Tente novamente ou contate seu administrador.';
  @override String attemptsRemaining(int count) => '$count tentativa${count == 1 ? '' : 's'} restante${count == 1 ? '' : 's'} antes do bloqueio';
  @override String tryAgainIn(int seconds) => 'Tente novamente em ${seconds}s';

  @override String get otmInstance => 'Instância OTM';
  @override String get swipeToRemove => 'Deslize para a esquerda para remover';
  @override String get scanNewInstance => 'Escanear nova instância';
  @override String get savedInstances => 'Instâncias salvas';
  @override String get noInstancesSaved => 'Nenhuma instância salva';
  @override String get tapToSetupInstance => 'Toque para configurar a instância OTM';
  @override String get confirmInstance => 'Confirmar instância';
  @override String get addOtmInstance => 'Adicionar instância OTM';
  @override String get saveAndUse => 'Salvar e usar esta instância';
  @override String get scanAgain => 'Escanear novamente';
  @override String get scanQrCode => 'Escanear código QR';
  @override String get enterManually => 'Inserir manualmente';
  @override String get pointCamera => 'Aponte a câmera para o código QR da instância OTM';
  @override String get urlValidating => 'A URL será validada enquanto você digita';
  @override String get urlNotRecognised => 'URL não reconhecida como instância OTM';
  @override String get otmProduction => 'OTM Produção';
  @override String get otmTest => 'OTM Teste';
  @override String get otmDevelopment => 'OTM Desenvolvimento';
  @override String otmDevelopmentN(int n) => 'OTM Desenvolvimento $n';

  @override String get navHome => 'Início';
  @override String get navSpotBids => 'Ofertas spot';
  @override String get navTendered => 'Licitações';
  @override String get navActive => 'Ativos';
  @override String get navInvoicing => 'Faturamento';

  @override String get accept => 'Aceitar';
  @override String get decline => 'Recusar';
  @override String get reject => 'Rejeitar';
  @override String get cancel => 'Cancelar';
  @override String get retry => 'Tentar novamente';
  @override String get refresh => 'Atualizar';
  @override String get save => 'Salvar';
  @override String get submit => 'Enviar';
  @override String get done => 'Concluído';
  @override String get edit => 'Editar';
  @override String get search => 'Pesquisar';
  @override String get signOut => 'Sair';
  @override String get signOutConfirm => 'Tem certeza que deseja sair?';
  @override String get yes => 'Sim';
  @override String get no => 'Não';

  @override String get shipment => 'Remessa';
  @override String get shipmentId => 'ID da remessa';
  @override String get weight => 'Peso';
  @override String get pickup => 'Coleta';
  @override String get delivery => 'Entrega';
  @override String get origin => 'Origem';
  @override String get destination => 'Destino';
  @override String get status => 'Status';
  @override String get language => 'Idioma';
  @override String get changeTheme => 'Alterar tema';

  @override String get homeTitle => 'LEAP Carrier';
  @override String get allShipments => 'Todas as remessas';
  @override String get noShipments => 'Sem remessas';
  @override String get pullToRefresh => 'Puxe para atualizar';
  @override String get needsAttention => 'Requer atenção';
  @override String activeShipments(int count) => '$count ativas';
  @override String tenderedCount(int count) => '$count pendentes';
  @override String spotBidsCount(int count) => '$count disponíveis';

  @override String get tenderedTitle => 'Remessas licitadas';
  @override String get tenderPending => 'Licitação pendente';
  @override String get tenderAccepted => 'Aceita';
  @override String get tenderRejected => 'Rejeitada';
  @override String get acceptTender => 'Aceitar licitação';
  @override String get declineTender => 'Recusar licitação';
  @override String get confirmAccept => 'Sim, aceitar';
  @override String get confirmDecline => 'Sim, rejeitar';
  @override String get actionCannotBeUndone => 'Esta ação não pode ser desfeita.';
  @override String get respondBy => 'Responder até';
  @override String get tenderApprovedSuccess => 'Licitação aprovada com sucesso!';
  @override String get tenderRejectedSuccess => 'Licitação rejeitada com sucesso!';
  @override String get noTenderedShipments => 'Nenhuma remessa licitada';
  @override String get noActionableTender => 'Nenhuma licitação acionável encontrada para esta remessa.';
  @override String get driverNotAssigned => 'Motorista não atribuído';
  @override String get smsNotSent => 'SMS não enviado';

  @override String get spotBidsTitle => 'Remessas com oferta spot';
  @override String get placeBid => 'Fazer oferta';
  @override String get submitBid => 'Enviar oferta';
  @override String get buyItNow => 'Comprar agora';
  @override String get marketRate => 'Taxa de mercado';
  @override String get yourBidAmount => 'Valor da sua oferta';
  @override String get bidSubmittedSuccess => 'Oferta enviada com sucesso!';
  @override String get noSpotBidShipments => 'Nenhuma remessa spot disponível';
  @override String get existingBidLabel => 'Sua oferta atual';
  @override String get bidWon => 'Oferta ganha';

  @override String get activeTitle => 'Remessas ativas';
  @override String get inTransit => 'Em trânsito';
  @override String get atPickup => 'Na coleta';
  @override String get etaLabel => 'ETA';
  @override String get noActiveShipments => 'Nenhuma remessa ativa';
  @override String get stopTimeline => 'Cronograma de paradas';
  @override String get addEvent => 'Adicionar evento';
  @override String get trackEvents => 'Rastrear eventos';
  @override String get noTrackingEvents => 'Nenhum evento de rastreamento';
  @override String get noEventUpdate => 'Sem atualização há';

  @override String get assignDriver => 'Atribuir motorista';
  @override String get assignDriverTruck => 'Atribuir motorista e caminhão';
  @override String get driverName => 'Nome do motorista';
  @override String get driverPhone => 'Telefone do motorista';
  @override String get vehicleReg => 'Número de registro do veículo';
  @override String get truckType => 'Tipo de caminhão';
  @override String get assignNow => 'Atribuir agora';
  @override String get assignLater => 'Atribuir depois';
  @override String get driverAssignedSuccess => 'Motorista atribuído com sucesso!';
  @override String get enterDriverPhone => 'Por favor insira o telefone do motorista';

  @override String get invoicingTitle => 'Faturamento';
  @override String get costs => 'Custos';
  @override String get invoices => 'Faturas';
  @override String get addCost => 'Adicionar custo';
  @override String get generateInvoice => 'Gerar fatura';
  @override String get costType => 'Tipo de custo';
  @override String get amount => 'Valor';
  @override String get description => 'Descrição';
  @override String get adjustmentReason => 'Motivo do ajuste';
  @override String get totalAmount => 'Total';
  @override String get invoiceHistoryComingSoon => 'Histórico de faturas em breve';
  @override String get costAddedSuccess => 'Custo adicionado com sucesso!';
  @override String get enterValidAmount => 'Por favor insira um valor válido';

  @override String get truckLcv => 'LCV (Pequeno)';
  @override String get truck24ft => '24 pés';
  @override String get truck32ft => '32 pés';
  @override String get truck40ft => '40 pés';
  @override String get truckTrailer => 'Semirreboque';
}
