import 'package:example/brain/payment_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:provider/provider.dart';

/// ======================================================================================
/// Arquivo         : ui/payment_tab.dart
/// Projeto         : PagSeguro Smart
/// Plataforma      : Android
/// Equipamentos    : Modelos de Maquininhas PagSeguro testados - P2 A7, P2 A11 & GPOS A11
/// Autor           : Fernando Takeo Miyaji
/// ======================================================================================

class PaymentTab extends StatefulWidget {
  const PaymentTab({super.key});

  @override
  State<PaymentTab> createState() => _PaymentTabState();
}

class _PaymentTabState extends State<PaymentTab> {
  final TextEditingController activationCodeController = TextEditingController(
    text: '749879',
  );

  final MoneyMaskedTextController moneyController = MoneyMaskedTextController(
    leftSymbol: 'R\$ ',
    decimalSeparator: ',',
  );

  @override
  void dispose() {
    activationCodeController.dispose();
    moneyController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PaymentProvider payProv = context.watch<PaymentProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (!payProv.isActivated)
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Ativação do PinPad',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: activationCodeController,
                            decoration: const InputDecoration(
                              labelText: 'Código',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.vpn_key),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => payProv.activatePinPad(
                            activationCodeController.text.trim(),
                          ),
                          icon: const Icon(Icons.lock_open),
                          label: const Text('Ativar'),
                        ),
                      ],
                    ),
                    if (payProv.displayMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(payProv.displayMessage),
                      ),
                  ],
                ),
              ),
            ),

          // CARD PAGAMENTO
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Pagamento',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    enabled: payProv.isActivated && !payProv.isInProgress,
                    controller: moneyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'R\$ 0,00',
                    ),
                    onChanged: (v) {
                      if (moneyController.numberValue < 1) {
                        payProv.displayMessage = 'Valor mínimo R\$1,00';
                      }
                    },
                  ),

                  if (payProv.displayMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(payProv.displayMessage),
                    ),

                  if (payProv.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Center(child: CircularProgressIndicator()),
                    ),

                  const SizedBox(height: 10),

                  if (!payProv.isInProgress)
                    ElevatedButton.icon(
                      onPressed: payProv.isActivated
                          ? () => payProv.doPayment(
                              context,
                              moneyController.numberValue,
                            )
                          : null,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Realizar Pagamento'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),

                  const SizedBox(height: 8),

                  ElevatedButton.icon(
                    onPressed: payProv.canAbort
                        ? () => payProv.abortTransaction()
                        : null,
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancelar Transação'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      minimumSize: const Size(double.infinity, 50),
                    ),
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
