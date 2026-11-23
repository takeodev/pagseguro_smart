import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pagseguro_smart/pagseguro_smart.dart';

/// Testes das adições não-quebrantes da 1.4.0: resultado tipado, controle de logs e o nome antigo [Constants].
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('plugpag_channel');
  final PagSeguroService pagSeguro = PagSeguroService();
  Map<dynamic, dynamic>? lastArgs;

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall call) async {
      lastArgs = call.arguments as Map<dynamic, dynamic>?;
      return {'success': true, 'message': 'Mock ${call.method}', 'data': lastArgs?['enabled']};
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  group('PagSeguroResult', () {
    test('converte o Map padrão e volta para ele', () {
      final PagSeguroResult result = PagSeguroResult.fromMap({'success': true, 'message': 'ok', 'data': 'GPOS780S'});

      expect(result.success, true);
      expect(result.message, 'ok');
      expect(result.data, 'GPOS780S');
      expect(result.toMap(), {'success': true, 'message': 'ok', 'data': 'GPOS780S'});
    });

    test('campos ausentes viram falha com mensagem vazia', () {
      final PagSeguroResult result = PagSeguroResult.fromMap({});

      expect(result.success, false);
      expect(result.message, '');
      expect(result.data, isNull);
    });

    test('toString não expõe os dados (LGPD)', () {
      const PagSeguroResult result = PagSeguroResult(success: true, message: 'ok', data: {'holder': '1234'});

      expect(result.toString(), isNot(contains('1234')));
    });

    test('extensão converte o retorno de um método do plugin', () async {
      final PagSeguroResult result = (await pagSeguro.getModel()).toPagSeguroResult();

      expect(result.success, true);
      expect(result.message, 'Mock getModel');
    });
  });

  test('setLogEnabled envia o valor ao Android', () async {
    await pagSeguro.setLogEnabled(false);
    expect(lastArgs?['enabled'], false);

    await pagSeguro.setLogEnabled(true);
    expect(lastArgs?['enabled'], true);
  });

  test('nome antigo Constants continua funcionando (compatibilidade)', () {
    // ignore: deprecated_member_use_from_same_package
    expect(Constants.allowWords, PagSeguroConstants.allowWords);
  });
}
