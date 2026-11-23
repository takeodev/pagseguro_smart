import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagseguro_smart/pagseguro_smart.dart';

/// Testes dos recursos da versão 1.4.0 que não dependem de uma maquininha real:
/// o canal nativo é substituído por um mock que registra os argumentos recebidos.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('plugpag_channel');
  final PagSeguroService pagSeguro = PagSeguroService();

  /// Último método chamado e seus argumentos (como o Android os receberia)
  String? lastMethod;
  Map<dynamic, dynamic>? lastArgs;

  setUp(() {
    lastMethod = null;
    lastArgs = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall call) async {
      lastMethod = call.method;
      lastArgs = call.arguments as Map<dynamic, dynamic>?;
      return {'success': true, 'message': 'Mock', 'data': null};
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  group('InstallmentModel', () {
    test('fromMap lê quantidade, parcela e total em centavos', () {
      // 2x de R$ 58,48 = R$ 116,96 (valores reais devolvidos pela GPOS780S para R$ 100,00)
      final InstallmentModel model = InstallmentModel.fromMap({'quantity': 2, 'amount': 5848, 'total': 11696});

      expect(model.quantity, 2);
      expect(model.amount, 5848);
      expect(model.total, 11696);
      expect(model.amountValue, 58.48);
      expect(model.totalValue, 116.96);
    });

    test('fromMap usa 0 quando faltam campos', () {
      final InstallmentModel model = InstallmentModel.fromMap({});

      expect(model.quantity, 0);
      expect(model.amount, 0);
      expect(model.total, 0);
    });

    test('fromList converte lista de mapas e ignora dados inválidos', () {
      final List<InstallmentModel> list = InstallmentModel.fromList([
        {'quantity': 2, 'amount': 5848, 'total': 11696},
        {'quantity': 3, 'amount': 4100, 'total': 12300},
      ]);

      expect(list.length, 2);
      expect(list.last.quantity, 3);
      expect(InstallmentModel.fromList(null), isEmpty);
      expect(InstallmentModel.fromList(['10000', '5848']), isEmpty);
    });

    test('toMap devolve os mesmos campos de fromMap', () {
      const InstallmentModel model = InstallmentModel(quantity: 2, amount: 5848, total: 11696);

      expect(InstallmentModel.fromMap(model.toMap()).total, model.total);
      expect(model.toMap(), {'quantity': 2, 'amount': 5848, 'total': 11696});
    });
  });

  group('PagSeguroLed', () {
    test('códigos conferem com o Wrapper PagSeguro', () {
      expect(PagSeguroLed.off.code, 0);
      expect(PagSeguroLed.red.code, 1);
      expect(PagSeguroLed.green.code, 2);
      expect(PagSeguroLed.yellow.code, 4);
      expect(PagSeguroLed.blue.code, 8);
    });
  });

  group('Argumentos enviados ao Android', () {
    test('setLed envia o código numérico da cor', () async {
      await pagSeguro.setLed(PagSeguroLed.green);

      expect(lastMethod, 'setLed');
      expect(lastArgs?['led'], 2);
    });

    test('beep envia frequência e duração', () async {
      await pagSeguro.beep(frequency: 5, duration: 300);

      expect(lastMethod, 'beep');
      expect(lastArgs?['frequency'], 5);
      expect(lastArgs?['duration'], 300);
    });

    test('calculateInstallments envia o valor em Reais e o tipo (opcional)', () async {
      await pagSeguro.calculateInstallments(value: 100);
      expect(lastMethod, 'calculateInstallments');
      expect(lastArgs?['amount'], 100);
      expect(lastArgs?['installmentType'], isNull);

      await pagSeguro.calculateInstallments(value: 100, installmentType: PagSeguroEnum.iForCustomer);
      expect(lastArgs?['installmentType'], PagSeguroEnum.iForCustomer.code);
    });

    test('printFromFile envia caminho, qualidade e avanço de papel padrão', () async {
      await pagSeguro.printFromFile(filePath: '/tmp/cupom.png');

      expect(lastMethod, 'printFromFile');
      expect(lastArgs?['filePath'], '/tmp/cupom.png');
      expect(lastArgs?['printerQuality'], 4);
      expect(lastArgs?['steps'], 70);
    });

    test('setPrintActionListener: padrão pergunta; "sem recibo" exige as três em false', () async {
      // Sem argumentos, askReceipt vale true (no Android "perguntar" vence SMS e direto)
      await pagSeguro.setPrintActionListener();
      expect(lastArgs?['askReceipt'], true);
      expect(lastArgs?['smsReceipt'], false);
      expect(lastArgs?['directReceipt'], false);

      await pagSeguro.setPrintActionListener(askReceipt: false, smsReceipt: false, directReceipt: false);
      expect(lastArgs?['askReceipt'], false);
      expect(lastArgs?['smsReceipt'], false);
      expect(lastArgs?['directReceipt'], false);
    });

    test('setPlugPagCustomPrinterLayout usa maxTimeShowPopup 20 por padrão', () async {
      await pagSeguro.setPlugPagCustomPrinterLayout(title: 'Recibo');

      expect(lastMethod, 'setPlugPagCustomPrinterLayout');
      expect(lastArgs?['maxTimeShowPopup'], 20);
    });
  });
}
