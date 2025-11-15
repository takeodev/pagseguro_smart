import 'package:example/brain/payment_provider.dart';
import 'package:flutter/material.dart';
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
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // TRANSACOES
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Transações',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  Wrap(
                    spacing: 10,
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
          const SizedBox(height: 20),

          // INFORMAÇÕES
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Informações',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  Wrap(
                    spacing: 10,
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

          const SizedBox(height: 20),

          // DISPOSITIVO
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Gerenciamento',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  Wrap(
                    spacing: 10,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.remove_red_eye),
                        onPressed: payProv.isActivated
                            ? payProv.isServiceNotBusy
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
