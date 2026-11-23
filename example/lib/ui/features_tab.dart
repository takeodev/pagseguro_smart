import 'dart:io';
import 'dart:ui' as ui;

import 'package:bot_toast/bot_toast.dart';
import 'package:example/brain/payment_provider.dart';
import 'package:example/ui/app_tour.dart';
import 'package:example/utils/dialog_helper.dart';
import 'package:flutter/material.dart';
import 'package:pagseguro_smart/pagseguro_smart.dart';
import 'package:provider/provider.dart';

/// ======================================================================================
/// Arquivo         : ui/features_tab.dart
/// Projeto         : PagSeguro Smart
/// Plataforma      : Android
/// Autor           : Fernando Takeo Miyaji
/// ======================================================================================
///
/// Aba "Recursos": demonstra as funcionalidades do Wrapper adicionadas na versão 1.4.0.
/// Cada botão chama um método do [PagSeguroService] e exibe a explicação do recurso junto
/// com o retorno ({success, message, data}). As explicações ficam em [kFeatureSections] e
/// também alimentam o tour guiado (ui/app_tour.dart).
///
/// IMPORTANTE: reutiliza a instância [PaymentProvider.pagSeguro]. Criar outro PagSeguroService
/// substituiria o handler do MethodChannel e os eventos de progresso de pagamento parariam de chegar.

/// Descrição de um recurso (botão) da aba
class FeatureInfo {
  /// Ícone do botão
  final IconData icon;

  /// Texto do botão; também é a chave para achar a ação em `_actions`
  final String label;

  /// Título da janela de resultado
  final String title;

  /// Explicação do recurso, mostrada na janela de resultado e no Tour
  final String description;

  const FeatureInfo(this.icon, this.label, this.title, this.description);
}

/// Seção (card) da aba de recursos
class FeatureSection {
  final String title;
  final String subtitle;
  final List<FeatureInfo> features;

  const FeatureSection(this.title, this.subtitle, this.features);
}

/// Recursos demonstrados, agrupados por seção (a ação de cada um está em _actions, por label)
const List<FeatureSection> kFeatureSections = [
  FeatureSection('Dispositivo', 'Informações e hardware da maquininha', [
    FeatureInfo(
      Icons.devices,
      'Modelo',
      'Modelo',
      'Descobre qual é o modelo da maquininha (ex.: A930, GPOS780). Útil para adaptar o app ao equipamento.',
    ),
    FeatureInfo(
      Icons.verified_user,
      'Permissão',
      'Permissão',
      'Verifica se este app tem autorização para usar o serviço PlugPagService (pagamentos). '
          'Em algumas maquininhas o serviço não responde a este teste e retorna "tempo esgotado".',
    ),
    FeatureInfo(
      Icons.volume_up,
      'Beep',
      'Beep',
      'Emite um bipe no alto-falante da maquininha (frequência 3, 300 ms). Serve para avisar o operador.',
    ),
    FeatureInfo(
      Icons.lightbulb,
      'LED',
      'LED',
      'Acende os LEDs da maquininha. Cada toque muda a cor, em sequência (as cores do PagSeguroLed, incluindo apagar).',
    ),
    FeatureInfo(
      Icons.cloud_sync,
      'Config. Remota',
      'Configuração Remota',
      'Pede ao serviço PagSeguro para baixar as configurações mais recentes. Normalmente isso é automático; '
          'o código -1033 indica que este equipamento/versão do serviço não aceita o comando.',
    ),
  ]),
  FeatureSection('Parcelamento (R\$ 100,00)', 'Calcula as parcelas de uma venda de R\$ 100,00 no crédito', [
    FeatureInfo(
      Icons.list,
      'Comprador (texto)',
      'Parcelas',
      'Calcula as parcelas no modelo "parcelado comprador" (juros pagos pelo cliente). Devolve uma lista simples de números: '
          'cada número é o valor de UMA parcela, em centavos. A 1ª posição é o 1x (à vista), a 2ª é o 2x, e assim por diante. '
          'Ex.: a lista [10000, 5848, 4100] significa 1x de R\$ 100,00, 2x de R\$ 58,48 e 3x de R\$ 41,00. '
          'A seção "Leitura" abaixo faz essa conversão para você.',
    ),
    FeatureInfo(
      Icons.calculate,
      'Comprador',
      'Parcelas Comprador',
      'Mesmo cálculo do anterior (juros pagos pelo cliente), mas organizado. Cada item tem: quantity = número de parcelas; '
          'amount = valor de cada parcela; total = quanto o cliente paga no final. Valores em centavos e a lista começa no 2x. '
          'Ex.: quantity 2, amount 5848, total 11696 = 2x de R\$ 58,48 = R\$ 116,96.',
    ),
    FeatureInfo(
      Icons.store,
      'Vendedor',
      'Parcelas Vendedor',
      'Calcula as parcelas no modelo "parcelado vendedor" (sem juros para o cliente; o lojista arca com o custo).',
    ),
    FeatureInfo(
      Icons.sync,
      'Assíncrono',
      'Parcelas (Assíncrono)',
      'Mesmo cálculo e mesmo formato do "Comprador (texto)" (lista de valores de cada parcela, em centavos), mas pedido em '
          'segundo plano: o Wrapper avisa por listener quando termina, sem o app ficar esperando.',
    ),
  ]),
  FeatureSection('Impressão e Cartão', 'Impressora e leitor de cartão', [
    FeatureInfo(
      Icons.print,
      'Imprimir Cupom',
      'Imprimir Cupom',
      'Monta a imagem de um cupom eletrônico de mercado (dados fictícios: itens, total e pagamento) e a imprime na impressora '
          'térmica da maquininha. Mostra como imprimir qualquer imagem (logotipo, comprovante ou cupom próprio) com printFromFile, '
          'informando o caminho do arquivo PNG. Largura ideal: 384 px.',
    ),
    FeatureInfo(
      Icons.credit_card,
      'Ler Cartão',
      'Dados do Cartão',
      'Aguarda você aproximar, inserir ou passar um cartão e lê só os dados básicos (BIN e portador), sem cobrar nada.',
    ),
  ]),
  FeatureSection('Subadquirente', 'Para facilitadores de pagamento (marketplaces)', [
    FeatureInfo(
      Icons.business,
      'Possui?',
      'Subadquirente',
      'Informa se há um subadquirente (facilitador de pagamento) configurado nesta maquininha.',
    ),
    FeatureInfo(
      Icons.badge,
      'Dados',
      'Dados do Subadquirente',
      'Mostra os dados do subadquirente configurado (nome, endereço, CNPJ/CPF etc.). Sem configuração, informa "Sem Subadquirente".',
    ),
  ]),
];

class FeaturesTab extends StatefulWidget {
  const FeaturesTab({super.key});

  @override
  State<FeaturesTab> createState() => _FeaturesTabState();
}

class _FeaturesTabState extends State<FeaturesTab> {
  /// Evita chamadas simultâneas ao PlugPagService (ele atende uma operação por vez)
  bool _busy = false;

  /// Índice da próxima cor do LED (cicla entre as cores)
  int _ledIndex = 0;

  /// Ação de cada recurso, indexada pelo label do botão
  late final Map<String, Future<Map<String, dynamic>> Function(PagSeguroService)> _actions = {
    'Modelo': (p) => p.getModel(),
    'Permissão': (p) => p.checkPermission(),
    'Beep': (p) => p.beep(frequency: 3, duration: 300),
    'LED': (p) => p.setLed(PagSeguroLed.values[_ledIndex++ % PagSeguroLed.values.length]),
    'Config. Remota': (p) => p.updateRemoteConfig(),
    'Comprador (texto)': (p) => p.calculateInstallments(value: 100),
    'Comprador': (p) => p.calculateInstallments(value: 100, installmentType: PagSeguroEnum.iForCustomer),
    'Vendedor': (p) => p.calculateInstallments(value: 100, installmentType: PagSeguroEnum.iForMerchant),
    'Assíncrono': (p) => p.asyncCalculateInstallments(value: 100),
    'Imprimir Cupom': (p) async => p.printFromFile(filePath: await _createReceiptImage()),
    'Ler Cartão': (p) => p.getCardData(),
    'Possui?': (p) => p.hasSubAcquirer(),
    'Dados': (p) => p.getSubAcquirerData(),
  };

  /// Centavos -> "R$ 58,48"
  String _money(num cents) => 'R\$ ${(cents / 100).toStringAsFixed(2).replaceAll('.', ',')}';

  /// Traduz o retorno de parcelas (centavos) para linguagem comum; null se "data" não for de parcelas.
  /// - Lista de números: valor de cada parcela (posição 1 = 1x).
  /// - Lista de mapas {quantity, amount, total}: parcelas estruturadas.
  String? _readInstallments(dynamic data) {
    if (data is! List || data.isEmpty) return null;
    // O Wrapper devolve cada parcela como texto em centavos ("5848"); aceita também números
    final List<num?> values = [for (final e in data) e is num ? e : (e is String ? num.tryParse(e) : null)];
    if (values.every((v) => v != null)) {
      return [for (int i = 0; i < values.length; i++) '${i + 1}x de ${_money(values[i]!)}'].join('\n');
    }
    if (data.every((e) => e is Map && e.containsKey('quantity') && e.containsKey('amount'))) {
      return [for (final Map e in data) '${e['quantity']}x de ${_money(e['amount'] as num)} = ${_money(e['total'] as num)}'].join('\n');
    }
    return null;
  }

  /// Executa a ação do recurso [f] e mostra a explicação + o resultado ({success, message, data}) em diálogo.
  /// `_busy` impede toques repetidos enquanto a maquininha responde; o `finally` libera o botão mesmo se der erro.
  Future<void> _run(FeatureInfo f, PagSeguroService pag) async {
    if (_busy) return;
    setState(() => _busy = true);
    BotToast.showText(text: '${f.title}...');
    try {
      final result = await _actions[f.label]!(pag);
      if (!mounted) return;
      // Mesmo padrão de janela da aba Comandos (DialogHelper: folha inferior + botão "Entendi")
      final String? reading = _readInstallments(result['data']);
      final bool ok = result['success'] == true;
      await DialogHelper.showBottom<void>(
        context: context,
        title: f.title,
        // ScrollHintBox: barra de rolagem visível + aviso "Role para ver mais" enquanto houver conteúdo abaixo
        content: ScrollHintBox(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('O que é:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(f.description),
              const SizedBox(height: 12),
              const Text('Resultado:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '${ok ? 'Sucesso' : 'Falha'}: ${result['message']}',
                style: TextStyle(color: ok ? Colors.green.shade800 : Colors.red.shade800),
              ),
              if (reading != null) ...[
                const SizedBox(height: 12),
                const Text('Leitura:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(reading),
              ],
              if (result['data'] != null) ...[
                const SizedBox(height: 12),
                const Text('Dados:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('${result['data']}'),
              ],
            ],
          ),
        ),
        actions: [DialogHelper.primaryButton('Entendi', () => Navigator.pop(context))],
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Gera, em arquivo temporário do sistema, a imagem PNG de um cupom eletrônico de mercado (dados fictícios)
  /// para demonstrar "printFromFile". Largura 384px = largura típica da impressora térmica.
  /// Retorna o caminho do arquivo gerado.
  Future<String> _createReceiptImage() async {
    const double width = 384, margin = 8, lineHeight = 26;
    const TextStyle normal = TextStyle(color: Colors.black, fontFamily: 'monospace', fontSize: 20);
    final TextStyle bold = normal.copyWith(fontWeight: FontWeight.bold);

    // Itens fictícios: descrição, quantidade, unidade e preço unitário
    const List<(String, double, String, double)> items = [
      ('ARROZ TIPO 1 5KG', 1, 'UN', 27.90),
      ('FEIJAO CARIOCA 1KG', 2, 'UN', 8.49),
      ('LEITE INTEGRAL 1L', 6, 'UN', 4.99),
      ('CAFE TORRADO 500G', 1, 'UN', 18.75),
      ('BANANA PRATA', 1.250, 'KG', 6.99),
      ('PAO FRANCES', 0.480, 'KG', 14.90),
    ];

    String money(double v) => v.toStringAsFixed(2).replaceAll('.', ',');
    double round2(double v) => (v * 100).round() / 100;
    String qty(double q, String un) => un == 'KG' ? q.toStringAsFixed(3) : q.toStringAsFixed(0);

    // Monta as linhas: (esquerda, direita, estilo, centralizada)
    final List<(String, String, TextStyle, bool)> lines = [];
    void center(String t, [TextStyle? s]) => lines.add((t, '', s ?? normal, true));
    void row(String l, String r, [TextStyle? s]) => lines.add((l, r, s ?? normal, false));
    void rule() => center('--------------------------------');

    center('SUPERMERCADO EXEMPLO', bold);
    center('Rua das Flores, 123 - Centro');
    center('CNPJ 00.000.000/0001-00');
    rule();
    center('CUPOM FISCAL ELETRONICO', bold);
    center('*** DEMONSTRACAO ***');
    final DateTime now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    row('CUPOM: 000123', '${two(now.day)}/${two(now.month)}/${now.year} ${two(now.hour)}:${two(now.minute)}');
    rule();
    row('ITEM DESCRICAO', 'TOTAL', bold);
    double total = 0;
    for (int i = 0; i < items.length; i++) {
      final (String name, double q, String un, double price) = items[i];
      final double sub = round2(q * price);
      total += sub;
      row('${(i + 1).toString().padLeft(3, '0')} $name', money(sub));
      row('    ${qty(q, un)} $un x ${money(price)}', '');
    }
    total = round2(total);
    rule();
    row('QTD. ITENS', items.length.toString());
    row('TOTAL R\$', money(total), bold);
    row('CARTAO CREDITO 2x', money(total));
    row('2x de R\$', money(round2(total / 2)));
    rule();
    center('Obrigado pela preferencia!');
    center('Volte sempre!');
    center('SEM VALOR FISCAL');

    // Desenha todas as linhas em uma imagem do tamanho exato do conteúdo
    final double height = lines.length * lineHeight + margin * 2;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), Paint()..color = Colors.white);

    TextPainter painter(String t, TextStyle s, double maxWidth) => TextPainter(
      text: TextSpan(text: t, style: s),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);

    double y = margin;
    for (final (String left, String right, TextStyle style, bool centered) in lines) {
      final double inner = width - margin * 2;
      if (centered) {
        final p = painter(left, style, inner);
        p.paint(canvas, Offset((width - p.width) / 2, y));
      } else {
        final TextPainter r = painter(right, style, inner);
        painter(left, style, inner - r.width - 8).paint(canvas, Offset(margin, y));
        r.paint(canvas, Offset(width - margin - r.width, y));
      }
      y += lineHeight;
    }

    final image = await recorder.endRecording().toImage(width.toInt(), height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('${Directory.systemTemp.path}/pagseguro_smart_cupom.png');
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    return file.path;
  }

  /// Botão padrão da aba (desabilitado enquanto há chamada em andamento).
  /// A `key` permite ao Tour localizar o botão na tela.
  Widget _button(FeatureInfo f, PagSeguroService pag) => ElevatedButton.icon(
    key: TourKeys.of('feat:${f.label}'),
    icon: Icon(f.icon),
    onPressed: _busy ? null : () => _run(f, pag),
    label: Text(f.label),
  );

  /// Card com título, explicação da seção e grupo de botões
  Widget _section(FeatureSection sec, PagSeguroService pag) => Card(
    key: TourKeys.of('sec:${sec.title}'),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Text(sec.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(sec.subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
          const Divider(),
          Wrap(spacing: 5, runSpacing: 5, alignment: WrapAlignment.center, children: [for (final f in sec.features) _button(f, pag)]),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final PagSeguroService pag = context.read<PaymentProvider>().pagSeguro;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 110), // folga embaixo para os botões flutuantes
      child: Column(children: [for (final sec in kFeatureSections) _section(sec, pag)]),
    );
  }
}
