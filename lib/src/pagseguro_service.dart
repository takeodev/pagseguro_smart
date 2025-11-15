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

  /// Inicializa o PinPad
  Future<Map<String, dynamic>> initPinPad(String activationCode) =>
      _invokeNative('initPinPad', {'activationCode': activationCode});

  /// Realiza o pagamento
  Future<Map<String, dynamic>> doPayment({
    required int type,
    required double value,
    int installmentType = PagSeguroInstallment.singlePay,
    int installments = 1,
    required String userReference,
    bool printReceipt = false,
  }) =>
      _invokeNative('doPayment', {
        'type': type,
        'amount': value,
        'installmentType': installmentType,
        'installments': installments,
        'userReference': userReference,
        'printReceipt': printReceipt,
      });

  /// Aborta / cancela transação em andamento
  Future<Map<String, dynamic>> abortTransaction() =>
      _invokeNative('abortTransaction');

  /// Realiza o estorno
  Future<Map<String, dynamic>> voidPayment({
    required String transactionCode,
    required String transactionId,
    int voidType = PagSeguroVoid.common,
    bool printReceipt = false,
  }) =>
      _invokeNative('voidPayment', {
        'transactionCode': transactionCode,
        'transactionId': transactionId,
        'voidType': voidType,
        'printReceipt': printReceipt,
      });

  /// Pega os Dados da Última Transação (Pode ser Estorno ou Pagamento)
  Future<Map<String, dynamic>> getLastTransaction() =>
      _invokeNative('getLastTransaction');

  /// Coleta dados do Dono da Maquininha
  Future<Map<String, dynamic>> getUserData() => _invokeNative('getUserData');

  /// Coleta Número de Série da Maquininha
  Future<Map<String, dynamic>> getSerialNumber() =>
      _invokeNative('getSerialNumber');

  /// Reinicia a Maquininha
  Future<Map<String, dynamic>> rebootDevice() => _invokeNative('rebootDevice');

  /// Verifica se o Serviço da PagSeguro está Livre
  Future<Map<String, dynamic>> isServiceNotBusy() =>
      _invokeNative('isServiceNotBusy');

  /// Reimpressão de Recibo: Via do Cliente
  Future<Map<String, dynamic>> reprintCustomerReceipt() =>
      _invokeNative('reprintCustomerReceipt');

  /// Reimpressão de Recibo: Via da Loja
  Future<Map<String, dynamic>> reprintEstablishmentReceipt() =>
      _invokeNative('reprintEstablishmentReceipt');

  /// Envia Recibo via SMS
  Future<Map<String, dynamic>> sendReceiptSMS(
          {required String transactionCode, required String phoneNumber}) =>
      _invokeNative('sendReceiptSMS',
          {'phoneNumber': phoneNumber, 'transactionCode': transactionCode});
}
