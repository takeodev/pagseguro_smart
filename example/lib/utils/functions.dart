import 'package:example/utils/dialog_helper.dart';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:pagseguro_smart/pagseguro_smart.dart';

/// ======================================================================================
/// Arquivo         : utils/functions.dart
/// Projeto         : PagSeguro Smart
/// Plataforma      : Android
/// Equipamentos    : Modelos de Maquininhas PagSeguro testados - P2 A7, P2 A11 & GPOS A11
/// Autor           : Fernando Takeo Miyaji
/// ======================================================================================

/// Exibe Diálogo para Seleção de Forma de Pagamento
Future<PagSeguroEnum?> payMethodDialog(BuildContext context) async {
  final PagSeguroEnum? result = await DialogHelper.showBottom<PagSeguroEnum>(
    context: context,
    title: 'Método de Pagamento',
    content: const Text('Selecione uma Forma de Pagamento.'),
    actions: [
      DialogHelper.primaryButton(
        'Crédito à Vista',
        () => Navigator.pop(context, PagSeguroEnum.tCredit),
      ),
      DialogHelper.primaryButton(
        'Débito',
        () => Navigator.pop(context, PagSeguroEnum.tDebit),
      ),
      DialogHelper.primaryButton(
        'Voucher',
        () => Navigator.pop(context, PagSeguroEnum.tVoucher),
      ),
      DialogHelper.primaryButton(
        'PIX (QrCode)',
        () => Navigator.pop(context, PagSeguroEnum.tPix),
      ),
      DialogHelper.secondaryButton('Cancelar', () => Navigator.pop(context)),
    ],
  );

  if (!context.mounted) return null;
  return result;
}

/// Exibe Diálogo perguntando se Imprime de Recibo de Estorno
Future<bool> voidDialog(BuildContext context) async {
  final result = await DialogHelper.showBottom<bool>(
    context: context,
    title: 'Impressão de Recibo',
    content: const Text('Deseja imprimir o recibo do Estorno?'),
    actions: [
      DialogHelper.secondaryButton('Não', () => Navigator.pop(context, false)),
      DialogHelper.primaryButton('Sim', () => Navigator.pop(context, true)),
    ],
  );

  if (!context.mounted) return false;
  return result ?? false;
}

/// Exibe Diálogo informando Dados do Usuário
Future<void> userDialog(BuildContext context, UserDataModel model) async {
  await DialogHelper.showBottom<void>(
    context: context,
    title: 'Dono da Maquininha',
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CPF/CNPJ: ${model.cnpjCpf}'),
        Text('Razão Social: ${model.companyName}'),
        Text('Responsável: ${model.userNickName}'),
        Text('E-mail: ${model.email}'),
        Text('Cidade: ${model.city} - ${model.addressState}'),
        Text('Endereço: ${model.address}'),
        Text('Complemento: ${model.addressComplement}'),
      ],
    ),
    actions: [
      DialogHelper.primaryButton('Entendi', () => Navigator.pop(context)),
    ],
  );
}

/// Exibe Diálogo informando Número de Série da Maquininha
Future<void> serialDialog(BuildContext context, String serialNumber) async {
  await DialogHelper.showBottom<void>(
    context: context,
    title: 'Número de Série',
    content: Text('Nº Série: $serialNumber'),
    actions: [
      DialogHelper.primaryButton('Entendi', () => Navigator.pop(context)),
    ],
  );
}

/// Exibe Diálogo perguntando o tipo de Via do Recibo
Future<String> receiptDialog(BuildContext context) async {
  final result = await DialogHelper.showBottom<String>(
    context: context,
    title: 'Reimpressão de Via',
    content: const Text('Selecione o tipo da impressão desejada:'),
    actions: [
      DialogHelper.primaryButton(
        'Via Cliente (SMS)',
        () => Navigator.pop(context, 'sms'),
      ),
      DialogHelper.primaryButton(
        'Via Cliente',
        () => Navigator.pop(context, 'customer'),
      ),
      DialogHelper.primaryButton(
        'Via Loja',
        () => Navigator.pop(context, 'establishment'),
      ),
      DialogHelper.secondaryButton('Cancelar', () => Navigator.pop(context)),
    ],
  );

  if (!context.mounted) return '';
  return result ?? '';
}

/// Exibe Diálogo solicitando o Preenchimento de Celular para Receber o Recibo via SMS
Future<String> celPhoneDialog(BuildContext context) async {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController celController = TextEditingController();
  final MaskTextInputFormatter celMask = MaskTextInputFormatter(
    mask: '(##) #.####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  final result = await DialogHelper.showBottom<String>(
    context: context,
    title: 'Recibo via SMS',
    content: Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Digite o Número do Celular:'),
          const SizedBox(height: 12),
          TextFormField(
            controller: celController,
            keyboardType: TextInputType.number,
            inputFormatters: [celMask],
            decoration: const InputDecoration(hintText: '(11) 9.XXXX-XXXX'),
            validator: (text) {
              if (text == null || text.trim().isEmpty) {
                return 'Digite um Número';
              } else if (celMask.unmaskText(text).length != 11) {
                return 'Número Inválido';
              }
              return null;
            },
          ),
        ],
      ),
    ),
    actions: [
      DialogHelper.secondaryButton('Cancelar', () => Navigator.pop(context)),
      DialogHelper.primaryButton('Enviar SMS', () {
        if (formKey.currentState!.validate()) {
          String tel = '+55 ${celMask.unmaskText(celController.text)}';
          Navigator.pop(context, tel);
        }
      }),
    ],
  );

  if (!context.mounted) return '';
  return result ?? '';
}

/// Exibe Diálogo confirmando se Reinício de Dispositivo
Future<bool> rebootDialog(BuildContext context) async {
  final result = await DialogHelper.showBottom<bool>(
    context: context,
    title: 'Reiniciar Dispositivo',
    content: const Text('Deseja reiniciar a maquininha?'),
    actions: [
      DialogHelper.secondaryButton('Não', () => Navigator.pop(context, false)),
      DialogHelper.primaryButton('Sim', () => Navigator.pop(context, true)),
    ],
  );

  if (!context.mounted) return false;
  return result ?? false;
}
