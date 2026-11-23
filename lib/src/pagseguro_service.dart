import 'package:flutter/services.dart';
import 'package:pagseguro_smart/pagseguro_smart.dart';

/// ======================================================================================
/// Arquivo         : src/pagseguro_service.dart
/// Projeto         : PagSeguro Smart
/// Plataforma      : Android
/// Equipamentos    : Modelos de Maquininhas PagSeguro testados - P2 A7, P2 A11 & GPOS A11
/// Autor           : Fernando Takeo Miyaji
/// ======================================================================================

/// Implementação do plugin PagSeguro Smart.
///
/// Cada método público chama o código nativo (Android) pelo canal `plugpag_channel` e
/// devolve sempre um `Map` no padrão `{success, message, data}`. Falhas de comunicação
/// (PlatformException ou erro inesperado) também viram `success: false`, sem lançar exceção.
///
/// Atenção: o canal é único. Cada instância criada registra o seu handler e substitui a
/// anterior, então use apenas uma instância (ex.: singleton) no App.
class PagSeguroService {
  final MethodChannel _methodChannel = const MethodChannel('plugpag_channel');

  /// Callback de progresso do pagamento: recebe a mensagem exibida pela maquininha e se
  /// o App pode abortar a transação naquele momento (`canAbort`).
  void Function(String message, bool canAbort)? onPaymentProgress;

  /// Último estado de permissão de cancelamento, decidido por [_abortPermission]
  bool _canAbort = false;

  /// Construtor - configura o canal de comunicação com o código nativo (Android).
  /// Todos os eventos recebidos do Kotlin são tratados em [_handleNativeCallbacks].
  PagSeguroService() {
    _methodChannel.setMethodCallHandler(_handleNativeCallbacks);
  }

  /// Recebe callbacks nativos e redireciona para os eventos apropriados
  Future<void> _handleNativeCallbacks(MethodCall call) async {
    final rawArgs = call.arguments;
    final data = (rawArgs is Map) ? Map<String, dynamic>.from(rawArgs) : <String, dynamic>{};

    switch (call.method) {
      case 'onPaymentProgress':
        final message = (data['message'] ?? '').toString();
        final newCanAbort = _abortPermission(message);
        onPaymentProgress?.call(message, newCanAbort);
        break;
    }
  }

  /// Avalia se há permissão para abortar pagamento, a partir da mensagem da maquininha.
  /// Mensagens de "permitir" (ex.: "aproxime", "insira", "chip") liberam o cancelamento;
  /// mensagens de "negar" (ex.: "retire", "senha", "transação autorizada") bloqueiam.
  /// Mensagens neutras mantêm o estado anterior. Os termos estão em [PagSeguroConstants].
  bool _abortPermission(String message) {
    if (message.isEmpty) return _canAbort;
    final lower = message.toLowerCase();

    // "Processando" indica que a maquininha está ocupada com a transação: não muda a permissão
    if (lower.contains('processando')) return _canAbort;
    if (_contains(lower, PagSeguroConstants.allowWords) || _contains(lower, PagSeguroConstants.allowPhrases)) {
      return _setAbort(true);
    }

    if (_contains(lower, PagSeguroConstants.denyWords) || _contains(lower, PagSeguroConstants.denyPhrases)) {
      return _setAbort(false);
    }

    return _canAbort;
  }

  /// Atualiza [_canAbort] e devolve o novo valor
  bool _setAbort(bool value) {
    if (_canAbort != value) _canAbort = value;
    return _canAbort;
  }

  /// Verdadeiro se [text] contém algum dos [patterns]
  bool _contains(String text, List<String> patterns) {
    for (final p in patterns) {
      if (text.contains(p)) return true;
    }
    return false;
  }

  /// Função para execução nativa com retorno e tratativa de erro.
  /// Sempre devolve `{success, message, data}`: se o Kotlin não enviar `success`, assume `false`.
  /// Em erro de canal, `message` recebe o texto do erro e `data` fica `null`.
  Future<Map<String, dynamic>> _invokeNative(String method, [Map<String, dynamic>? arguments]) async {
    try {
      final result = await _methodChannel.invokeMethod(method, arguments);
      final map = result is Map ? Map<String, dynamic>.from(result) : {};

      return {'success': map['success'] ?? false, 'message': map['message'] ?? '', 'data': map['data']};
    } on PlatformException catch (e) {
      return {'success': false, 'message': e.message ?? e.code, 'data': null};
    } catch (e) {
      return {'success': false, 'message': e.toString(), 'data': null};
    }
  }

  // Métodos "async" (ex.: asyncInitPinPad) usam os listeners do Wrapper no Kotlin: a resposta
  // só chega quando o fluxo termina, e o andamento é informado por onPaymentProgress.

  /// Liga ou desliga os logs informativos do plugin no Logcat do Android (padrão: ligados). - 1.4.0
  /// Erros continuam sendo registrados. Recomendado desligar em produção para reduzir o volume de logs.
  /// Obs.: os logs do próprio Wrapper da PagSeguro não são controlados pelo plugin.
  Future<Map<String, dynamic>> setLogEnabled(bool enabled) => _invokeNative('setLogEnabled', {'enabled': enabled});

  /// Verifica se PinPad está Ativo. data: não usado. Falha se o PinPad não estiver ativado.
  Future<Map<String, dynamic>> isAuthenticated() => _invokeNative('isAuthenticated');
  Future<Map<String, dynamic>> asyncIsAuthenticated() => _invokeNative('asyncIsAuthenticated');

  /// Inicializa (ativa) o PinPad com o código de ativação fornecido pelo PagSeguro.
  /// Retorna `success: true` quando a ativação termina sem erro; caso contrário, `message` traz o motivo.
  Future<Map<String, dynamic>> initPinPad(String activationCode) => _invokeNative('initPinPad', {'activationCode': activationCode});
  Future<Map<String, dynamic>> asyncInitPinPad(String activationCode) =>
      _invokeNative('asyncInitPinPad', {'activationCode': activationCode});

  /// Configura Estilo (Cores) de Impressão de Recibo.
  /// Cada [Color] é enviado como inteiro ARGB (`toARGB32`). Cores não informadas são enviadas como `null`.
  /// [isAsync] troca apenas o nome do método nativo (`asyncSetStyles`).
  Future<Map<String, dynamic>> setStyleData({
    bool isAsync = false,
    Color? headTextColor,
    Color? headBackgroundColor,
    Color? contentTextColor,
    Color? contentTextValue1Color,
    Color? contentTextValue2Color,
    Color? positiveButtonTextColor,
    Color? positiveButtonBackground,
    Color? negativeButtonTextColor,
    Color? negativeButtonBackground,
    Color? genericButtonBackground,
    Color? genericButtonTextColor,
    Color? genericSmsEditTextBackground,
    Color? genericSmsEditTextTextColor,
    Color? lineColor,
  }) =>
      _invokeNative(isAsync ? 'asyncSetStyles' : 'setStyleData', {
        'headTextColor': headTextColor?.toARGB32(),
        'headBackgroundColor': headBackgroundColor?.toARGB32(),
        'contentTextColor': contentTextColor?.toARGB32(),
        'contentTextValue1Color': contentTextValue1Color?.toARGB32(),
        'contentTextValue2Color': contentTextValue2Color?.toARGB32(),
        'positiveButtonTextColor': positiveButtonTextColor?.toARGB32(),
        'positiveButtonBackground': positiveButtonBackground?.toARGB32(),
        'negativeButtonTextColor': negativeButtonTextColor?.toARGB32(),
        'negativeButtonBackground': negativeButtonBackground?.toARGB32(),
        'genericButtonBackground': genericButtonBackground?.toARGB32(),
        'genericButtonTextColor': genericButtonTextColor?.toARGB32(),
        'genericSmsEditTextBackground': genericSmsEditTextBackground?.toARGB32(),
        'genericSmsEditTextTextColor': genericSmsEditTextTextColor?.toARGB32(),
        'lineColor': lineColor?.toARGB32(),
      });

  /// Realiza o Pagamento (síncrono).
  /// - [value]: valor em **Reais** (ex.: 10.50). O Kotlin converte para centavos. Mínimo de R$ 1,00.
  /// - [type]: meio de pagamento ([PagSeguroEnum] `tCredit`, `tDebit`, `tPix`...).
  /// - [installments]: número de parcelas; é forçado para 1 quando [installmentType] é `iSinglePay`.
  /// - [userReference]: identificação do pedido no App. O Kotlin remove o que não for letra ou número
  ///   e exige de 1 a 10 caracteres restantes.
  /// - [printReceipt]: se true, imprime o recibo ao final.
  /// Falha (`success: false`) com valor menor que R$ 1,00, [userReference] inválido, cancelamento
  /// ou erro do Wrapper (a mensagem em `message` explica o motivo).
  Future<Map<String, dynamic>> doPayment({
    PagSeguroEnum type = PagSeguroEnum.tCredit,
    required double value,
    PagSeguroEnum installmentType = PagSeguroEnum.iSinglePay,
    int installments = 1,
    required String userReference,
    bool printReceipt = false,
  }) =>
      _invokeNative('doPayment', {
        'type': type.code,
        'amount': value,
        'installmentType': installmentType.code,
        'installments': installmentType == PagSeguroEnum.iSinglePay ? 1 : installments,
        'userReference': userReference,
        'printReceipt': printReceipt,
      });
  Future<Map<String, dynamic>> doAsyncPayment({
    PagSeguroEnum type = PagSeguroEnum.tCredit,
    required double value,
    PagSeguroEnum installmentType = PagSeguroEnum.iSinglePay,
    int installments = 1,
    required String userReference,
    bool printReceipt = false,
  }) =>
      _invokeNative('doAsyncPayment', {
        'type': type.code,
        'amount': value,
        'installmentType': installmentType.code,
        'installments': installmentType == PagSeguroEnum.iSinglePay ? 1 : installments,
        'userReference': userReference,
        'printReceipt': printReceipt,
      });

  /// Aborta / cancela transação em andamento.
  /// Só deve ser chamado quando [onPaymentProgress] informa `canAbort: true` (ver [_abortPermission]),
  /// pois é nesse momento que a maquininha aceita o cancelamento.
  Future<Map<String, dynamic>> abortTransaction() => _invokeNative('abortTransaction');
  Future<Map<String, dynamic>> asyncAbortTransaction() => _invokeNative('asyncAbortTransaction');

  /// Realiza o estorno de uma transação anterior.
  /// [transactionCode] e [transactionId] identificam a transação original (vêm do retorno de um pagamento
  /// ou de [getLastTransaction]). [voidType]: `vCommon` (estorno padrão) ou `vQrCode`.
  Future<Map<String, dynamic>> voidPayment({
    required String transactionCode,
    required String transactionId,
    PagSeguroEnum voidType = PagSeguroEnum.vCommon,
    bool printReceipt = false,
  }) =>
      _invokeNative('voidPayment', {
        'transactionCode': transactionCode,
        'transactionId': transactionId,
        'voidType': voidType.code,
        'printReceipt': printReceipt,
      });
  Future<Map<String, dynamic>> asyncVoidPayment({
    required String transactionCode,
    required String transactionId,
    PagSeguroEnum voidType = PagSeguroEnum.vCommon,
    bool printReceipt = false,
  }) =>
      _invokeNative('asyncVoidPayment', {
        'transactionCode': transactionCode,
        'transactionId': transactionId,
        'voidType': voidType.code,
        'printReceipt': printReceipt,
      });

  /// Pega os Dados da Última Transação (Pode ser Estorno ou Pagamento)
  Future<Map<String, dynamic>> getLastTransaction() => _invokeNative('getLastTransaction');
  Future<Map<String, dynamic>> asyncGetLastTransaction() => _invokeNative('asyncGetLastTransaction');

  /// Coleta dados do Dono da Maquininha. Atenção LGPD: são dados pessoais, não registre em logs nem os exiba sem necessidade.
  Future<Map<String, dynamic>> getUserData() => _invokeNative('getUserData');

  /// Coleta Número de Série da Maquininha
  Future<Map<String, dynamic>> getSerialNumber() => _invokeNative('getSerialNumber');

  /// Reinicia a Maquininha
  Future<Map<String, dynamic>> rebootDevice() => _invokeNative('rebootDevice');

  /// Verifica se o Serviço da PagSeguro está Livre
  Future<Map<String, dynamic>> isServiceBusy() => _invokeNative('isServiceBusy');

  /// Reimpressão de Recibo: Via do Cliente
  Future<Map<String, dynamic>> reprintCustomerReceipt() => _invokeNative('reprintCustomerReceipt');
  Future<Map<String, dynamic>> asyncReprintCustomerReceipt() => _invokeNative('asyncReprintCustomerReceipt');

  /// Reimpressão de Recibo: Via da Loja
  Future<Map<String, dynamic>> reprintEstablishmentReceipt() => _invokeNative('reprintEstablishmentReceipt');
  Future<Map<String, dynamic>> asyncReprintEstablishmentReceipt() => _invokeNative('asyncReprintEstablishmentReceipt');

  /// Envia Recibo via SMS para [phoneNumber] referente à transação [transactionCode].
  /// Atenção LGPD: o telefone é dado pessoal; não o registre em logs.
  Future<Map<String, dynamic>> sendReceiptSMS({required String transactionCode, required String phoneNumber}) =>
      _invokeNative('sendReceiptSMS', {'phoneNumber': phoneNumber, 'transactionCode': transactionCode});

  /// Configura Ações de Impressão de Recibo (o que a maquininha oferece ao final da venda):
  /// [askReceipt] pergunta se deseja recibo, [smsReceipt] oferece envio por SMS e [directReceipt] imprime direto.
  /// ATENÇÃO: o padrão de [askReceipt] é `true` e, no Android, a prioridade é perguntar > SMS > direto. Para usar SMS ou
  /// impressão direta, envie `askReceipt: false`. Com as três em `false` o recibo do cliente é dispensado.
  Future<Map<String, dynamic>> setPrintActionListener({bool askReceipt = true, bool smsReceipt = false, bool directReceipt = false}) =>
      _invokeNative('setPrintActionListener', {'askReceipt': askReceipt, 'smsReceipt': smsReceipt, 'directReceipt': directReceipt});

  /// Define Estilo Visual (Cores e Texto) do Recibo do Cliente.
  /// Cores são enviadas como inteiro ARGB. [maxTimeShowPopup] é o tempo máximo, em segundos, que o popup do
  /// recibo (perguntar / SMS / imprimir) fica na tela (padrão 20, igual ao do Android).
  Future<Map<String, dynamic>> setPlugPagCustomPrinterLayout({
    String? title,
    Color? titleColor,
    Color? confirmTextColor,
    Color? cancelTextColor,
    Color? windowBackgroundColor,
    Color? buttonBackgroundColor,
    Color? buttonBackgroundColorDisabled,
    Color? sendSMSTextColor,
    int maxTimeShowPopup = 20,
  }) =>
      _invokeNative('setPlugPagCustomPrinterLayout', {
        'title': title,
        'titleColor': titleColor?.toARGB32(),
        'confirmTextColor': confirmTextColor?.toARGB32(),
        'cancelTextColor': cancelTextColor?.toARGB32(),
        'windowBackgroundColor': windowBackgroundColor?.toARGB32(),
        'buttonBackgroundColor': buttonBackgroundColor?.toARGB32(),
        'buttonBackgroundColorDisabled': buttonBackgroundColorDisabled?.toARGB32(),
        'sendSMSTextColor': sendSMSTextColor?.toARGB32(),
        'maxTimeShowPopup': maxTimeShowPopup,
      });

  // ======================================================================================
  // 1.4.0 - DISPOSITIVO
  // ======================================================================================

  /// Modelo da Maquininha (data: String)
  Future<Map<String, dynamic>> getModel() => _invokeNative('getModel');

  /// Verifica capacidade de Hardware (constantes "PlugPag" do Wrapper). data: bool
  Future<Map<String, dynamic>> hasCapability(int capability) => _invokeNative('hasCapability', {'capability': capability});

  /// Verifica capacidade de Software, com [mode] opcional. data: bool
  Future<Map<String, dynamic>> hasSoftwareCapability(int capability, {int? mode}) =>
      _invokeNative('hasSoftwareCapability', {'capability': capability, 'mode': mode});

  /// Verifica se o App tem permissão para usar o PlugPagService. data: bool
  Future<Map<String, dynamic>> checkPermission() => _invokeNative('checkPermission');

  /// Emite Beep. [frequency] de 0 a 6 e [duration] em milissegundos
  Future<Map<String, dynamic>> beep({int frequency = 3, int duration = 200}) =>
      _invokeNative('beep', {'frequency': frequency, 'duration': duration});

  /// Acende o LED da Maquininha (ver [PagSeguroLed])
  Future<Map<String, dynamic>> setLed(PagSeguroLed led) => _invokeNative('setLed', {'led': led.code});

  /// Atualiza as Configurações Remotas do PlugPagService
  Future<Map<String, dynamic>> updateRemoteConfig() => _invokeNative('updateRemoteConfig');

  /// Abre o fluxo de OnBoarding (primeiro acesso) do PlugPagService
  Future<Map<String, dynamic>> startOnBoarding() => _invokeNative('startOnBoarding');

  /// Lê BIN e Portador do Cartão sem transação (exige cartão).
  /// data: {result, message, bin, holder, cardHolder}. Atenção LGPD: dados pessoais, não registre em logs.
  Future<Map<String, dynamic>> getCardData() => _invokeNative('getCardData');

  // ======================================================================================
  // 1.4.0 - ATIVAÇÃO / DESATIVAÇÃO
  // ======================================================================================

  /// Desativa o PinPad (mesmo código usado na ativação)
  Future<Map<String, dynamic>> deactivate(String activationCode) => _invokeNative('deactivate', {'activationCode': activationCode});
  Future<Map<String, dynamic>> asyncDeactivate(String activationCode) =>
      _invokeNative('asyncDeactivate', {'activationCode': activationCode});

  /// Invalida a Autenticação atual (exige nova ativação)
  Future<Map<String, dynamic>> invalidateAuthentication() => _invokeNative('invalidateAuthentication');

  /// Ativação via PagBank (fluxo do PlugPagService)
  Future<Map<String, dynamic>> initPagBankActivation() => _invokeNative('initPagBankActivation');

  // ======================================================================================
  // 1.4.0 - PARCELAMENTO
  // ======================================================================================

  /// Calcula Parcelas de [value] (em Reais).
  /// - Sem [installmentType]: data é `List<String>` (textos do Wrapper, Parcelado Comprador).
  /// - Com [installmentType] (iForMerchant / iForCustomer): data é `List<Map>` {quantity, amount, total} em centavos;
  ///   use [InstallmentModel.fromList] para converter.
  Future<Map<String, dynamic>> calculateInstallments({required double value, PagSeguroEnum? installmentType}) =>
      _invokeNative('calculateInstallments', {'amount': value, 'installmentType': installmentType?.code});
  Future<Map<String, dynamic>> asyncCalculateInstallments({required double value}) =>
      _invokeNative('asyncCalculateInstallments', {'amount': value});

  // ======================================================================================
  // 1.4.0 - IMPRESSÃO
  // ======================================================================================

  /// Imprime uma Imagem a partir de [filePath] (caminho absoluto no dispositivo).
  /// [printerQuality] de 1 a 4 e [steps] = avanço de papel após a impressão.
  Future<Map<String, dynamic>> printFromFile({required String filePath, int printerQuality = 4, int steps = 70}) =>
      _invokeNative('printFromFile', {'filePath': filePath, 'printerQuality': printerQuality, 'steps': steps});

  // ======================================================================================
  // 1.4.0 - SUBADQUIRENTE
  // ======================================================================================

  /// Verifica se há Subadquirente (facilitador de pagamento) configurado. data: bool
  Future<Map<String, dynamic>> hasSubAcquirer() => _invokeNative('hasSubAcquirer');

  /// data: Map com os dados do Subadquirente. Atenção LGPD: contém CPF/CNPJ e telefone.
  /// Falha quando não há Subadquirente configurado.
  Future<Map<String, dynamic>> getSubAcquirerData() => _invokeNative('getSubAcquirerData');

  /// Configura Subadquirente (todos os campos são texto). Respeite os tamanhos máximos definidos pelo Wrapper.
  /// Atenção LGPD: CPF/CNPJ e telefone são dados pessoais; não os registre em logs.
  Future<Map<String, dynamic>> initializeSubAcquirer({
    required String name,
    required String address,
    required String city,
    required String uf,
    required String country,
    required String zipCode,
    required String mcc,
    required String cnpjCpf,
    required String docType,
    required String telephone,
    required String fullName,
    required String merchantId,
  }) =>
      _invokeNative('initializeSubAcquirer', {
        'name': name,
        'address': address,
        'city': city,
        'uf': uf,
        'country': country,
        'zipCode': zipCode,
        'mcc': mcc,
        'cnpjCpf': cnpjCpf,
        'docType': docType,
        'telephone': telephone,
        'fullName': fullName,
        'merchantId': merchantId,
      });

  /// Remove o Subadquirente configurado
  Future<Map<String, dynamic>> invalidateSubAcquirer() => _invokeNative('invalidateSubAcquirer');

  // ======================================================================================
  // 1.4.0 - DEEPLINK
  // ======================================================================================

  /// Registra o Deeplink que o PlugPagService abre ao iniciar uma Venda
  Future<Map<String, dynamic>> setSellDeeplink(String deeplink) => _invokeNative('setSellDeeplink', {'deeplink': deeplink});
  Future<Map<String, dynamic>> removeSellDeeplink() => _invokeNative('removeSellDeeplink');
}
