import 'package:bot_toast/bot_toast.dart';
import 'package:example/brain/payment_provider.dart';
import 'package:example/ui/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// ======================================================================================
/// Arquivo         : main.dart
/// Projeto         : PagSeguro Smart
/// Plataforma      : Android
/// Equipamentos    : Modelos de Maquininhas PagSeguro testados - P2 A7, P2 A11 & GPOS A11
/// Autor           : Fernando Takeo Miyaji
/// ======================================================================================

/// Ponto de entrada do App Example. O [PaymentProvider] é criado aqui, uma única vez, e
/// disponibilizado às telas pelo Provider; o BotToast mostra as mensagens de status.
void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => PaymentProvider())],
      child: const MyApp(),
    ),
  );
}

/// Raiz do App: MaterialApp com o BotToast (mensagens flutuantes) e a [SplashScreen] como tela inicial (ela abre a MainScreen).
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [BotToastNavigatorObserver()],
      builder: BotToastInit(),
      title: 'PagSeguro Smart Demo',
      home: const SplashScreen(), // abre com a splash animada e depois vai para a MainScreen
    );
  }
}
