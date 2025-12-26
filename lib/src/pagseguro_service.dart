import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pagseguro_smart/pagseguro_smart.dart';

/// ======================================================================================
/// Arquivo         : src/pagseguro_service.dart
/// Projeto         : PagSeguro Smart
/// Plataforma      : Android
/// Equipamentos    : Modelos de Maquininhas PagSeguro testados - P2 A7, P2 A11 & GPOS A11
/// Autor           : Fernando Takeo Miyaji
/// ======================================================================================

/// Implementação do plugin PagSeguro Smart
class PagSeguroService {
  final MethodChannel _methodChannel = const MethodChannel('plugpag_channel');

  /// Callbacks públicos do plugin
  void Function(String message, bool canAbort)? onPaymentProgress;

  bool _canAbort = false;

  /// Construtor - configura o canal de comunicação com o código nativo (Android).
  /// Todos os eventos recebidos do Kotlin são tratados em [_handleNativeCallbacks].
  PagSeguroService() {
    _methodChannel.setMethodCallHandler(_handleNativeCallbacks);
  }

  /// Recebe callbacks nativos e redireciona para os eventos apropriados
  Future<void> _handleNativeCallbacks(MethodCall call) async {
    final rawArgs = call.arguments;
    final data = (rawArgs is Map)
        ? Map<String, dynamic>.from(rawArgs)
        : <String, dynamic>{};

    switch (call.method) {
      case 'onPaymentProgress':
        final message = (data['message'] ?? '').toString();
        final newCanAbort = _abortPermission(message);
        onPaymentProgress?.call(message, newCanAbort);
        break;
    }
  }

  /// Avalia se há permissão para abortar pagamento
  bool _abortPermission(String message) {
    if (message.isEmpty) return _canAbort;
    final lower = message.toLowerCase();

    if (lower.contains('processando')) return _canAbort;
    if (_contains(lower, Constants.allowWords) ||
        _contains(lower, Constants.allowPhrases)) {
      return _setAbort(true);
    }

    if (_contains(lower, Constants.denyWords) ||
        _contains(lower, Constants.denyPhrases)) {
      return _setAbort(false);
    }

    return _canAbort;
  }

  bool _setAbort(bool value) {
    if (_canAbort != value) _canAbort = value;
    return _canAbort;
  }

  bool _contains(String text, List<String> patterns) {
    for (final p in patterns) {
      if (text.contains(p)) return true;
    }
    return false;
  }

  /// Função para execução nativa com retorno e tratativa de erro
  Future<Map<String, dynamic>> _invokeNative(
    String method, [
    Map<String, dynamic>? arguments,
  ]) async {
    try {
      final result = await _methodChannel.invokeMethod(method, arguments);
      final map = result is Map ? Map<String, dynamic>.from(result) : {};

      return {
        'success': map['success'] ?? false,
        'message': map['message'] ?? '',
        'data': map['data']
      };
    } on PlatformException catch (e) {
      return {'success': false, 'message': e.message ?? e.code, 'data': null};
    } catch (e) {
      return {'success': false, 'message': e.toString(), 'data': null};
    }
  }

  /// Verifica se PinPad está Ativo
  Future<Map<String, dynamic>> isAuthenticated() =>
      _invokeNative('isAuthenticated');
  Future<Map<String, dynamic>> asyncIsAuthenticated() =>
      _invokeNative('asyncIsAuthenticated');

  /// Inicializa o PinPad
  Future<Map<String, dynamic>> initPinPad(String activationCode) =>
      _invokeNative('initPinPad', {'activationCode': activationCode});
  Future<Map<String, dynamic>> asyncInitPinPad(String activationCode) =>
      _invokeNative('asyncInitPinPad', {'activationCode': activationCode});

  /// Configura Estilo (Cores) de Impressão de Recibo
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
      _invokeNative(
        isAsync ? 'asyncSetStyles' : 'setStyleData',
        {
          'headTextColor': (headTextColor ?? Colors.black).toARGB32(),
          'headBackgroundColor':
              (headBackgroundColor ?? const Color(0xFFE13C70)).toARGB32(),
          'contentTextColor':
              (contentTextColor ?? const Color(0xFFDFDFE0)).toARGB32(),
          'contentTextValue1Color':
              (contentTextValue1Color ?? const Color(0xFFFFE000)).toARGB32(),
          'contentTextValue2Color':
              (contentTextValue2Color ?? Colors.black).toARGB32(),
          'positiveButtonTextColor':
              (positiveButtonTextColor ?? Colors.black).toARGB32(),
          'positiveButtonBackground':
              (positiveButtonBackground ?? const Color(0xFFFF358C)).toARGB32(),
          'negativeButtonTextColor':
              (negativeButtonTextColor ?? const Color(0xFF777778)).toARGB32(),
          'negativeButtonBackground':
              (negativeButtonBackground ?? Colors.black).toARGB32(),
          'genericButtonBackground':
              (genericButtonBackground ?? Colors.black).toARGB32(),
          'genericButtonTextColor':
              (genericButtonTextColor ?? const Color(0xFFFF358C)).toARGB32(),
          'genericSmsEditTextBackground':
              (genericSmsEditTextBackground ?? Colors.black).toARGB32(),
          'genericSmsEditTextTextColor':
              (genericSmsEditTextTextColor ?? const Color(0xFFFF358C))
                  .toARGB32(),
          'lineColor': (lineColor ?? Colors.black).toARGB32(),
        },
      );

  /// Realiza o Pagamento
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
        'installments':
            installmentType == PagSeguroEnum.iSinglePay ? 1 : installments,
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
        'installments':
            installmentType == PagSeguroEnum.iSinglePay ? 1 : installments,
        'userReference': userReference,
        'printReceipt': printReceipt,
      });

  /// Aborta / cancela transação em andamento
  Future<Map<String, dynamic>> abortTransaction() =>
      _invokeNative('abortTransaction');
  Future<Map<String, dynamic>> asyncAbortTransaction() =>
      _invokeNative('asyncAbortTransaction');

  /// Realiza o estorno
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
  Future<Map<String, dynamic>> getLastTransaction() =>
      _invokeNative('getLastTransaction');
  Future<Map<String, dynamic>> asyncGetLastTransaction() =>
      _invokeNative('asyncGetLastTransaction');

  /// Coleta dados do Dono da Maquininha
  Future<Map<String, dynamic>> getUserData() => _invokeNative('getUserData');

  /// Coleta Número de Série da Maquininha
  Future<Map<String, dynamic>> getSerialNumber() =>
      _invokeNative('getSerialNumber');

  /// Reinicia a Maquininha
  Future<Map<String, dynamic>> rebootDevice() => _invokeNative('rebootDevice');

  /// Verifica se o Serviço da PagSeguro está Livre
  Future<Map<String, dynamic>> isServiceBusy() =>
      _invokeNative('isServiceBusy');

  /// Reimpressão de Recibo: Via do Cliente
  Future<Map<String, dynamic>> reprintCustomerReceipt() =>
      _invokeNative('reprintCustomerReceipt');
  Future<Map<String, dynamic>> asyncReprintCustomerReceipt() =>
      _invokeNative('asyncReprintCustomerReceipt');

  /// Reimpressão de Recibo: Via da Loja
  Future<Map<String, dynamic>> reprintEstablishmentReceipt() =>
      _invokeNative('reprintEstablishmentReceipt');
  Future<Map<String, dynamic>> asyncReprintEstablishmentReceipt() =>
      _invokeNative('asyncReprintEstablishmentReceipt');

  /// Envia Recibo via SMS
  Future<Map<String, dynamic>> sendReceiptSMS(
          {required String transactionCode, required String phoneNumber}) =>
      _invokeNative('sendReceiptSMS',
          {'phoneNumber': phoneNumber, 'transactionCode': transactionCode});

  /// Configura Ações de Impressão de Recibo
  Future<Map<String, dynamic>> setPrintActionListener({
    bool askCustomerReceipt = false,
    bool smsReceipt = false,
  }) =>
      _invokeNative('setPrintActionListener', {
        'askCustomerReceipt': askCustomerReceipt,
        'smsReceipt': smsReceipt,
      });

  /// Define Estilo Visual (Cores e Texto) do Recibo do Cliente
  Future<Map<String, dynamic>> setPlugPagCustomPrinterLayout(
    String title, {
    Color? titleColor,
    Color? confirmTextColor,
    Color? cancelTextColor,
    Color? windowBackgroundColor,
    Color? buttonBackgroundColor,
    Color? buttonBackgroundColorDisabled,
    Color? sendSMSTextColor,
    int maxTimeShowPopup = 10,
  }) =>
      _invokeNative(
        'setPlugPagCustomPrinterLayout',
        {
          'title': title,
          'titleColor': (titleColor ?? const Color(0xFFFFE000)).toARGB32(),
          'confirmTextColor': (confirmTextColor ?? Colors.black).toARGB32(),
          'cancelTextColor':
              (cancelTextColor ?? const Color(0xFF777778)).toARGB32(),
          'windowBackgroundColor':
              (windowBackgroundColor ?? const Color(0xFFE13C70)).toARGB32(),
          'buttonBackgroundColor':
              (buttonBackgroundColor ?? Colors.black).toARGB32(),
          'buttonBackgroundColorDisabled':
              (buttonBackgroundColorDisabled ?? Colors.black).toARGB32(),
          'sendSMSTextColor':
              (sendSMSTextColor ?? const Color(0xFFFFE000)).toARGB32(),
          'maxTimeShowPopup': maxTimeShowPopup,
        },
      );
}
