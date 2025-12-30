import 'package:example/brain/payment_provider.dart';
import 'package:example/ui/commands_tab.dart';
import 'package:example/ui/payment_tab.dart';
import 'package:flutter/material.dart';
import 'package:pagseguro_smart/pagseguro_smart.dart';
import 'package:provider/provider.dart';

/// ======================================================================================
/// Arquivo         : ui/payment_screen.dart
/// Projeto         : PagSeguro Smart
/// Plataforma      : Android
/// Equipamentos    : Modelos de Maquininhas PagSeguro testados - P2 A7, P2 A11 & GPOS A11
/// Autor           : Fernando Takeo Miyaji
/// ======================================================================================

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final PaymentProvider payProv = context.read<PaymentProvider>();
      await payProv.isAuthenticated();
      await payProv.setFullStyleData(
        title: 'Recibo PagSeguro Smart',
        layoutPreset: LayoutPreset.darkBlue,
        maxTimeShowPopup: 15,
      );
      await payProv.setPrintActionListener(askReceipt: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,

        appBar: AppBar(
          title: const Text('PagSeguro Smart Demo'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.payment), text: 'Pagamento'),
              Tab(icon: Icon(Icons.settings_applications), text: 'Comandos'),
            ],
          ),
        ),

        body: TabBarView(children: [const PaymentTab(), const CommandsTab()]),
      ),
    );
  }
}
