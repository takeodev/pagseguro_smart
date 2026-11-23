import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagseguro_smart/pagseguro_smart.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('plugpag_channel');
  final pagSeguro = PagSeguroService();

  // Os testes substituem o canal nativo por um mock: nada é enviado a uma maquininha real.
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'initPinPad':
          return {
            'success': true,
            'message': 'Mock: PinPad iniciado',
            'data': null,
          };

        case 'doPayment':
          final amount = methodCall.arguments['amount'];
          return {
            'success': true,
            'message': 'Mock: Pagamento iniciado',
            'data': {
              'amount': amount,
              'userReference': methodCall.arguments['userReference'],
            }
          };

        case 'abortTransaction':
          return {
            'success': true,
            'message': 'Mock: Pagamento cancelado',
            'data': null,
          };

        default:
          return {
            'success': false,
            'message': 'Método não mockado',
            'data': null,
          };
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('initPinPad retorna Map simulado corretamente', () async {
    final result = await pagSeguro.initPinPad('CODIGO_DE_ATIVACAO');

    expect(result, isA<Map>());
    expect(result['success'], true);
    expect(result['message'], 'Mock: PinPad iniciado');
  });

  test('doPayment retorna Map simulado corretamente', () async {
    PagSeguroEnum payType = PagSeguroEnum.tCredit;
    final result = await pagSeguro.doPayment(
      type: payType,
      value: 1.50,
      userReference: 't${payType.code}p123',
    );

    expect(result, isA<Map>());
    expect(result['success'], true);
    expect(result['data']['amount'], 1.50);
    expect(result['data']['userReference'], 't${payType.code}p123');
  });

  test('Códigos dos tipos de pagamento conferem com o Wrapper da PagSeguro', () {
    expect(PagSeguroEnum.tCredit.code, 1); // TYPE_CREDITO
    expect(PagSeguroEnum.tDebit.code, 2); // TYPE_DEBITO
    expect(PagSeguroEnum.tVoucher.code, 3); // TYPE_VOUCHER
    expect(PagSeguroEnum.tQrCode.code, 4); // TYPE_QRCODE
    expect(PagSeguroEnum.tPix.code, 5); // TYPE_PIX
    expect(PagSeguroEnum.tPreAuthCard.code, 6); // TYPE_PREAUTO_CARD
    expect(PagSeguroEnum.tQrCodeCredit.code, 7); // TYPE_QRCODE_CREDITO
    expect(PagSeguroEnum.tPreAuthKeyed.code, 8); // TYPE_PREAUTO_KEYED
  });

  test('abortTransaction retorna Map simulado corretamente', () async {
    final result = await pagSeguro.abortTransaction();

    expect(result, isA<Map>());
    expect(result['success'], true);
    expect(result['message'], 'Mock: Pagamento cancelado');
  });
}
