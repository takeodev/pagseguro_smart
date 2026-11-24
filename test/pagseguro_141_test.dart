import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagseguro_smart/pagseguro_smart.dart';

/// Testes da versão 1.4.1 que não dependem de maquininha: código do evento de progresso ([PagSeguroService.onPaymentEvent])
/// e tempo limite opcional ([Duration] `timeout`) nas consultas bloqueantes.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('plugpag_channel');
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const codec = StandardMethodCodec();

  /// Simula o Android enviando um evento de progresso ao Dart
  Future<void> sendProgress(Map<String, dynamic> args) async {
    await messenger.handlePlatformMessage('plugpag_channel', codec.encodeMethodCall(MethodCall('onPaymentProgress', args)), (_) {});
  }

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('onPaymentEvent', () {
    test('recebe o código do evento junto da mensagem e do canAbort', () async {
      final pagSeguro = PagSeguroService();
      final events = <List<dynamic>>[];
      final messages = <String>[];
      pagSeguro.onPaymentProgress = (message, canAbort) => messages.add(message);
      pagSeguro.onPaymentEvent = (code, message, canAbort) => events.add([code, message, canAbort]);

      await sendProgress({'eventCode': PagSeguroConstants.eventWaitingCard, 'message': 'APROXIME, INSIRA OU PASSE O CARTÃO'});
      await sendProgress({'eventCode': PagSeguroConstants.eventSaleApproved, 'message': 'TRANSAÇÃO AUTORIZADA'});

      expect(messages.length, 2, reason: 'onPaymentProgress continua sendo chamado como antes');
      expect(events, [
        [0, 'APROXIME, INSIRA OU PASSE O CARTÃO', true],
        [18, 'TRANSAÇÃO AUTORIZADA', false],
      ]);
    });

    test('usa -1 quando o Android não envia o código', () async {
      final pagSeguro = PagSeguroService();
      int? received;
      pagSeguro.onPaymentEvent = (code, message, canAbort) => received = code;

      await sendProgress({'message': 'PROCESSANDO'});

      expect(received, PagSeguroConstants.eventDefault);
    });
  });

  group('timeout opcional', () {
    test('sem timeout espera a resposta normalmente', () async {
      final pagSeguro = PagSeguroService();
      messenger.setMockMethodCallHandler(channel, (call) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return {'success': true, 'message': 'Ok', 'data': null};
      });

      final result = await pagSeguro.getUserData();

      expect(result['success'], true);
    });

    test('com timeout e serviço travado devolve tempo esgotado', () async {
      final pagSeguro = PagSeguroService();
      final never = Completer<Object?>();
      messenger.setMockMethodCallHandler(channel, (call) => never.future);

      final result = await pagSeguro.getUserData(timeout: const Duration(milliseconds: 50));

      expect(result, {'success': false, 'message': PagSeguroService.timeoutMessage, 'data': null});
    });

    test('com timeout e resposta a tempo devolve a resposta do Android', () async {
      final pagSeguro = PagSeguroService();
      messenger.setMockMethodCallHandler(channel, (call) async => {'success': true, 'message': call.method, 'data': 1});

      for (final call in [
        () => pagSeguro.isAuthenticated(timeout: const Duration(seconds: 1)),
        () => pagSeguro.asyncIsAuthenticated(timeout: const Duration(seconds: 1)),
        () => pagSeguro.getSerialNumber(timeout: const Duration(seconds: 1)),
        () => pagSeguro.isServiceBusy(timeout: const Duration(seconds: 1)),
        () => pagSeguro.getLastTransaction(timeout: const Duration(seconds: 1)),
        () => pagSeguro.asyncGetLastTransaction(timeout: const Duration(seconds: 1)),
      ]) {
        final result = await call();
        expect(result['success'], true);
        expect(result['data'], 1);
      }
    });
  });
}
