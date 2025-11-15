import 'package:example/ui/commands_tab.dart';
import 'package:example/ui/payment_tab.dart';
import 'package:flutter/material.dart';

/// ======================================================================================
/// Arquivo         : ui/payment_screen.dart
/// Projeto         : PagSeguro Smart
/// Plataforma      : Android
/// Equipamentos    : Modelos de Maquininhas PagSeguro testados - P2 A7, P2 A11 & GPOS A11
/// Autor           : Fernando Takeo Miyaji
/// ======================================================================================

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

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
