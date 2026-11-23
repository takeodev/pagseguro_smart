import 'package:example/brain/payment_provider.dart';
import 'package:example/ui/about_sheet.dart';
import 'package:example/ui/app_tour.dart';
import 'package:example/ui/commands_tab.dart';
import 'package:example/ui/features_tab.dart';
import 'package:example/ui/payment_tab.dart';
import 'package:flutter/material.dart';
import 'package:pagseguro_smart/pagseguro_smart.dart';
import 'package:provider/provider.dart';

/// ======================================================================================
/// Arquivo         : ui/main_screen.dart
/// Projeto         : PagSeguro Smart
/// Plataforma      : Android
/// Equipamentos    : Modelos de Maquininhas PagSeguro testados - P2 A7, P2 A11 & GPOS A11
/// Autor           : Fernando Takeo Miyaji
/// ======================================================================================

/// Tela principal do Example: barra com o botão do Tour e 3 abas (Pagamento, Comandos e Recursos).
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();

    // Depois do 1º frame: verifica a ativação do PinPad e aplica o visual do recibo
    // (tema azul escuro, título do recibo e maxTimeShowPopup = 15). Isso é configuração de exemplo, não obrigatória.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final PaymentProvider payProv = context.read<PaymentProvider>();
      await payProv.isAuthenticated();
      await payProv.setFullStyleData(title: 'Recibo PagSeguro Smart', layoutPreset: LayoutPreset.darkBlue, maxTimeShowPopup: 15);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,

        appBar: AppBar(
          title: const Text('PagSeguro Smart Demo'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.payment), text: 'Pagamento'),
              Tab(icon: Icon(Icons.settings_applications), text: 'Comandos'),
              Tab(icon: Icon(Icons.extension), text: 'Recursos'),
            ],
          ),
        ),

        body: TabBarView(children: [const PaymentTab(), const CommandsTab(), const FeaturesTab()]),

        // Botões flutuantes sempre visíveis: "Sobre" (pequeno) acima de "Tour guiado".
        // As abas deixam folga embaixo (padding) para os botões não cobrirem o último item da lista.
        floatingActionButton: Builder(
          // Builder: precisa de um contexto abaixo do DefaultTabController para o Tour trocar de aba
          builder: (ctx) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FloatingActionButton.small(
                heroTag: 'fab_about',
                tooltip: 'Sobre o desenvolvedor',
                onPressed: () => showAboutSheet(ctx),
                child: const Icon(Icons.info_outline),
              ),
              const SizedBox(height: 10),
              FloatingActionButton.extended(
                heroTag: 'fab_tour',
                onPressed: () => AppTour.start(ctx),
                icon: const Icon(Icons.tour),
                label: const Text('Tour guiado'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
