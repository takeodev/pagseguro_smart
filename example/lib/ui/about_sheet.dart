import 'package:bot_toast/bot_toast.dart';
import 'package:example/utils/dialog_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ======================================================================================
/// Arquivo         : ui/about_sheet.dart
/// Projeto         : PagSeguro Smart
/// Plataforma      : Android
/// Autor           : Fernando Takeo Miyaji
/// ======================================================================================

/// Links públicos do projeto e do desenvolvedor exibidos na tela "Sobre"
/// (o app apenas mostra e copia os links; não abre o navegador nem envia nenhum dado).
const List<(String, String)> kAboutLinks = [
  ('Site do desenvolvedor', 'https://www.takeodev.com/'),
  ('Pacote no pub.dev', 'https://pub.dev/packages/pagseguro_smart'),
  ('Código no GitHub', 'https://github.com/takeodev/pagseguro_smart'),
];

/// Abre a janela "Sobre" (mesmo padrão das demais janelas do app): logo, créditos do desenvolvedor e links.
Future<void> showAboutSheet(BuildContext context) {
  return DialogHelper.showBottom<void>(
    context: context,
    title: 'Sobre',
    content: ScrollHintBox(
      maxHeight: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Image.asset('assets/logo_takeo.png', height: 90, semanticLabel: 'Logotipo do desenvolvedor Takeo')),
          const SizedBox(height: 14),
          const Text('PagSeguro Smart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text(
            'Pacote Flutter gratuito e de código aberto para integrar maquininhas PagSeguro (Wrapper PlugPagService), '
            'desenvolvido por Fernando Takeo Miyaji (Takeo). Este App Example demonstra todos os recursos.',
          ),
          const SizedBox(height: 10),
          const Text('Se o pacote te ajudou, deixe um "like" no pub.dev e uma estrela no GitHub: é a melhor forma de apoiar o projeto.'),
          const SizedBox(height: 14),
          const Text('Links:', style: TextStyle(fontWeight: FontWeight.bold)),
          for (final (String label, String url) in kAboutLinks) _linkRow(label, url),
          const SizedBox(height: 10),
          const Text(
            'Projeto independente: não é um produto oficial da PagSeguro/PagBank.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    ),
    actions: [DialogHelper.primaryButton('Fechar', () => Navigator.pop(context))],
  );
}

/// Linha com o nome do link, o endereço (selecionável) e um botão para copiar
Widget _linkRow(String label, String url) {
  return Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              SelectableText(url, style: const TextStyle(color: Color(0xFF3D1BD3))),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Copiar link',
          icon: const Icon(Icons.copy),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: url));
            BotToast.showText(text: 'Link copiado!');
          },
        ),
      ],
    ),
  );
}
