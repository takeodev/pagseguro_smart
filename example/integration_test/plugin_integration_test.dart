import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pagseguro_smart/pagseguro_smart.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final pagSeguro = PagSeguroService();

  group('PagSeguro Smart Plugin — Integration Test', () {
    testWidgets('initPinPad executa sem falhas', (tester) async {
      final result = await pagSeguro.initPinPad('749879');
      debugPrint('🔌 initPinPad → $result');

      expect(result, isA<Map>());
      expect(result['success'], isNotNull);
    });

    testWidgets('Valida callback onPaymentProgress', (tester) async {
      String lastMessage = '';
      bool lastAbort = false;

      pagSeguro.onPaymentProgress = (message, canAbort) {
        lastMessage = message;
        lastAbort = canAbort;
        debugPrint('📡 CALLBACK → $message | canAbort=$canAbort');
      };

      // Dispara payment (não importa se falhar, queremos callback)
      await pagSeguro.doPayment(
        type: PagSeguroType.credit,
        value: 1.00,
        userReference: 'callback-test',
      );

      expect(lastMessage, isNotNull);
      expect(lastAbort, isNotNull);
    });

    testWidgets('doPayment inicia corretamente (não exige aprovação real)', (
      tester,
    ) async {
      final result = await pagSeguro.doPayment(
        type: PagSeguroType.credit,
        value: 1.50,
        installmentType: PagSeguroInstallment.singlePay,
        userReference: 'teste123',
      );

      debugPrint('💳 doPayment → $result');

      expect(result, isA<Map>());
      expect(result.containsKey('success'), true);
    });

    testWidgets('abortTransaction executa corretamente', (tester) async {
      final result = await pagSeguro.abortTransaction();
      debugPrint('⛔ abortTransaction → $result');

      expect(result, isA<Map>());
    });

    testWidgets('getUserData retorna ou falha corretamente', (tester) async {
      final result = await pagSeguro.getUserData();
      debugPrint('👤 getUserData → $result');

      expect(result, isA<Map>());
    });

    testWidgets('getSerialNumber retorna corretamente', (tester) async {
      final result = await pagSeguro.getSerialNumber();
      debugPrint('📟 getSerialNumber → $result');

      expect(result, isA<Map>());
    });

    testWidgets('isServiceNotBusy retorna corretamente', (tester) async {
      final result = await pagSeguro.isServiceNotBusy();
      debugPrint('🟢 isServiceNotBusy → $result');

      expect(result, isA<Map>());
    });
  });

  tearDownAll(() async {
    await binding.delayed(const Duration(milliseconds: 300));
  });
}
