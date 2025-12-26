import 'package:example/brain/payment_provider.dart';
import 'package:flutter/material.dart';
import 'package:pagseguro_smart/pagseguro_smart.dart';
import 'package:provider/provider.dart';

/// ======================================================================================
/// Arquivo         : ui/commands_tab.dart
/// Projeto         : PagSeguro Smart
/// Plataforma      : Android
/// Equipamentos    : Modelos de Maquininhas PagSeguro testados - P2 A7, P2 A11 & GPOS A11
/// Autor           : Fernando Takeo Miyaji
/// ======================================================================================

class CommandsTab extends StatelessWidget {
  const CommandsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final PaymentProvider payProv = context.watch<PaymentProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          // CONFIGURAÇÕES DE LAYOUT
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  const Text(
                    'Configurações de Layouts',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  Wrap(
                    spacing: 5,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.color_lens_rounded),
                        onPressed:
                            payProv.isActivated &&
                                payProv.actualPreset !=
                                    LayoutPreset.pagseguroDefault
                            ? () => payProv.setStyleData(
                                LayoutPreset.pagseguroDefault,
                              )
                            : null,
                        label: const Text('PagSeguro'),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.colorize),
                        onPressed:
                            payProv.isActivated &&
                                payProv.actualPreset != LayoutPreset.darkBlue
                            ? () => payProv.setStyleData(LayoutPreset.darkBlue)
                            : null,
                        label: const Text('Tema Azul'),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.border_color),
                        onPressed:
                            payProv.isActivated &&
                                payProv.actualPreset != LayoutPreset.darkGreen
                            ? () => payProv.setStyleData(LayoutPreset.darkGreen)
                            : null,
                        label: const Text('Tema Verde'),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.format_color_fill),
                        onPressed:
                            payProv.isActivated &&
                                payProv.actualPreset != LayoutPreset.lightCustom
                            ? () =>
                                  payProv.setStyleData(LayoutPreset.lightCustom)
                            : null,
                        label: const Text('Tema Leve'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // CONFIGURAÇÕES RECIBO CLIENTE
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  const Text(
                    'Configuração de Recibo do Cliente',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  Wrap(
                    spacing: 5,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.question_mark_rounded),
                        onPressed: payProv.isActivated && !payProv.askPrint
                            ? () => payProv.setPrintActionListener(
                                askCustomerReceipt: true,
                              )
                            : null,
                        label: const Text('Perguntar'),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.sms_outlined),
                        onPressed: payProv.isActivated && !payProv.smsPrint
                            ? () => payProv.setPrintActionListener(
                                smsReceipt: true,
                              )
                            : null,
                        label: const Text('Via SMS'),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.print_disabled),
                        onPressed:
                            payProv.isActivated &&
                                (payProv.askPrint || payProv.smsPrint)
                            ? () => payProv.setPrintActionListener()
                            : null,
                        label: const Text('Sem Recibo'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // TRANSACOES
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  const Text(
                    'Transações',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  Wrap(
                    spacing: 5,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.receipt_long),
                        onPressed:
                            payProv.isActivated &&
                                payProv.transactionCode != null
                            ? () => payProv.reprintReceipt(context)
                            : null,
                        label: const Text('2ª Via Recibo'),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.history),
                        onPressed: payProv.isActivated
                            ? payProv.getLastTransaction
                            : null,
                        label: const Text('Última Transação'),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.undo),
                        onPressed:
                            payProv.isActivated &&
                                payProv.transactionCode != null &&
                                payProv.transactionId != null
                            ? () => payProv.voidPayment(context)
                            : null,
                        label: const Text('Estornar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // INFORMAÇÕES
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  const Text(
                    'Informações',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  Wrap(
                    spacing: 5,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.person_pin),
                        onPressed: payProv.isActivated
                            ? () => payProv.getUserData(context)
                            : null,
                        label: const Text('Dono da Maquininha'),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.qr_code_2),
                        onPressed: payProv.isActivated
                            ? () => payProv.getSerialNumber(context)
                            : null,
                        label: const Text('Número de Série'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // DISPOSITIVO
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  const Text(
                    'Gerenciamento',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  Wrap(
                    spacing: 5,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.remove_red_eye),
                        onPressed: payProv.isActivated
                            ? payProv.isServiceBusy
                            : null,
                        label: const Text('Verificar Serviço'),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.restart_alt),
                        onPressed: !payProv.isInProgress && !payProv.isLoading
                            ? () => payProv.rebootDevice(context)
                            : null,
                        label: const Text('Reiniciar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
