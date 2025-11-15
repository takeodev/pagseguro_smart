import 'package:bot_toast/bot_toast.dart';
import 'package:example/brain/payment_provider.dart';
import 'package:example/ui/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// ======================================================================================
/// Arquivo         : main.dart
/// Projeto         : PagSeguro Smart
/// Plataforma      : Android
/// Equipamentos    : Modelos de Maquininhas PagSeguro testados - P2 A7, P2 A11 & GPOS A11
/// Autor           : Fernando Takeo Miyaji
/// ======================================================================================

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => PaymentProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [BotToastNavigatorObserver()],
      builder: BotToastInit(),
      title: 'PagSeguro Smart Demo',
      home: const MainScreen(),
    );
  }
}
