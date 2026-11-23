import 'package:example/ui/features_tab.dart';
import 'package:flutter/material.dart';

/// ======================================================================================
/// Arquivo         : ui/app_tour.dart
/// Projeto         : PagSeguro Smart
/// Plataforma      : Android
/// Autor           : Fernando Takeo Miyaji
/// ======================================================================================
///
/// Tour guiado do App Example: esmaece a tela, destaca um componente por vez e mostra uma dica.
/// Percorre as 3 abas (troca de aba e rola a tela sozinho). Não usa pacotes externos.
///
/// Para um componente participar do tour: `key: TourKeys.of('id')` e um [TourStep] com o mesmo id.
/// Passos cujo componente não está na tela (ex.: "Ativar" depois de ativado) são pulados.

/// GlobalKeys fixas por id, para o tour localizar os componentes na tela.
/// O mesmo id sempre devolve a mesma chave; a chave deve ficar em um único widget por vez.
class TourKeys {
  static final Map<String, GlobalKey> _keys = {};

  static GlobalKey of(String id) => _keys.putIfAbsent(id, () => GlobalKey(debugLabel: 'tour_$id'));
}

/// Um passo do tour. [id] nulo = passo de texto, sem destaque.
/// [group] = nome do bloco (card) a que o passo pertence; [block] = passo-resumo do bloco.
class TourStep {
  /// Índice da aba onde o componente está: 0 = Pagamento, 1 = Comandos, 2 = Recursos
  final int tab;

  /// Id do componente a destacar (mesmo de `TourKeys.of`); nulo = passo só de texto
  final String? id;
  final String title;
  final String text;

  /// Nome do bloco (card) ao qual o passo pertence; usado por "Pular bloco"
  final String? group;

  /// true = passo-resumo do bloco (aparece antes dos botões e tem o botão "Pular bloco")
  final bool block;

  const TourStep(this.tab, this.id, this.title, this.text, {this.group, this.block = false});
}

/// Item (botão) de um bloco do tour: id da chave, rótulo do botão e explicação
typedef _Item = (String id, String label, String text);

/// Monta a lista de passos do tour e o inicia sobre a tela atual.
class AppTour {
  /// Padrão do tour: um passo-resumo do bloco (destaca o card inteiro e lista os botões)
  /// seguido de um passo por botão (destaca cada botão e explica o que ele faz).
  static List<TourStep> _group(int tab, String blockId, String blockTitle, String summary, List<_Item> items) => [
    TourStep(
      tab,
      blockId,
      'Bloco: $blockTitle',
      '$summary\n\nBotões deste bloco: ${items.map((i) => i.$2).join(', ')}. '
          'Vou explicar um por um.',
      group: blockTitle,
      block: true,
    ),
    for (final i in items) TourStep(tab, i.$1, i.$2, i.$3, group: blockTitle),
  ];

  /// Passos do tour, na ordem de exibição
  static List<TourStep> get steps => [
    const TourStep(
      0,
      null,
      'Bem-vindo ao Tour!',
      'Este app demonstra todos os recursos do plugin pagseguro_smart.\n\n'
          'Cada aba é dividida em blocos (cards). Para cada bloco, primeiro mostro um resumo e '
          'depois explico cada botão. Em qualquer resumo de bloco você pode tocar em "Pular bloco". '
          'Toque em "Próximo" para começar.',
    ),
    // ---- Aba Pagamento
    const TourStep(
      0,
      'pay_code',
      'Código de Ativação',
      'Antes de vender, a maquininha precisa ser ativada com o código da conta PagSeguro (aparece só enquanto não estiver ativada).',
      group: 'Pagamento',
    ),
    const TourStep(
      0,
      'pay_activate',
      'Ativar',
      'Envia o código para ativar o PinPad. Depois de ativado, esta área é substituída pela de Pagamento.',
      group: 'Pagamento',
    ),
    const TourStep(0, 'pay_amount', 'Valor da Venda', 'Digite o valor a cobrar. O mínimo é R\$ 1,00.', group: 'Pagamento'),
    const TourStep(
      0,
      'pay_do',
      'Realizar Pagamento',
      'Inicia a cobrança: a maquininha pede o cartão e a senha do cliente e mostra o andamento na tela.',
      group: 'Pagamento',
    ),
    const TourStep(
      0,
      'pay_cancel',
      'Cancelar Transação',
      'Interrompe um pagamento em andamento. Só fica ativo enquanto há uma transação que pode ser cancelada.',
      group: 'Pagamento',
    ),
    // ---- Aba Comandos
    const TourStep(
      1,
      'cmd_async',
      'Modo Assíncrono',
      'Escolhe COMO o plugin conversa com o serviço PagSeguro. Vale para ativação, pagamento, cancelamento, estorno e consultas.\n\n'
          'SÍNCRONO (desligado): o plugin chama o Wrapper e espera o resultado numa thread de segundo plano. '
          'Vantagem: fluxo mais simples e previsível, com menos pontos de falha. Melhor para: operações curtas, '
          'integração mais simples e depuração.\n\n'
          'ASSÍNCRONO (ligado): o plugin só dispara a operação e o Wrapper devolve o resultado por listeners (callbacks), '
          'sem manter uma thread presa esperando. Vantagem: é o modelo nativo do Wrapper para operações longas '
          'e interativas. Melhor para: pagamentos com o cliente digitando senha, aproximando o cartão ou cancelando no meio.\n\n'
          'Nos dois modos a tela recebe as mensagens de progresso e o resultado final igual. Na dúvida, use o assíncrono para '
          'pagamentos e o síncrono para o resto.',
      group: 'Modo Assíncrono',
    ),
    ..._group(
      1,
      'cmd_layout',
      'Cores / Layouts',
      'Troca o tema visual das janelas e do recibo impresso na maquininha. O tema ativo fica desabilitado. '
          'Exige maquininha ativada.',
      [
        ('cmd_layout_pagseguro', 'PagSeguro', 'Aplica o tema padrão com as cores oficiais do PagSeguro.'),
        ('cmd_layout_blue', 'Azul', 'Aplica um tema escuro em tons de azul nas janelas e no recibo.'),
        ('cmd_layout_green', 'Verde', 'Aplica um tema escuro em tons de verde nas janelas e no recibo.'),
        ('cmd_layout_sunset', 'Por do Sol', 'Aplica um tema em tons quentes (laranja e vermelho), como um pôr do sol.'),
        ('cmd_layout_light', 'Suave / Leve', 'Aplica um tema claro e suave, com cores leves, bom para ambientes bem iluminados.'),
      ],
    ),
    ..._group(
      1,
      'cmd_receipt',
      'Recibo do Cliente',
      'Define o que acontece com o recibo do cliente ao final de uma venda aprovada. Só uma opção fica ativa por vez.',
      [
        (
          'cmd_receipt_ask',
          'Perguntar',
          'Ao final da venda, a maquininha pergunta ao cliente se ele quer o recibo e de que forma (impresso ou SMS).',
        ),
        ('cmd_receipt_sms', 'Via SMS', 'O recibo é enviado ao cliente por SMS, sem imprimir. Economiza papel.'),
        ('cmd_receipt_direct', 'Direto', 'Imprime o recibo automaticamente, sem perguntar nada ao cliente.'),
        ('cmd_receipt_none', 'Sem Recibo', 'Desliga o recibo do cliente: nada é perguntado, impresso nem enviado.'),
      ],
    ),
    ..._group(
      1,
      'cmd_trans',
      'Transações',
      'Consulta e desfaz vendas já realizadas. '
          'Os botões dependem de existir uma venda anterior.',
      [
        ('cmd_trans_reprint', '2ª Via Recibo', 'Reimprime o recibo da última venda aprovada. Só fica ativo depois de uma venda.'),
        ('cmd_trans_last', 'Última Transação', 'Consulta no serviço PagSeguro os dados da última transação feita nesta maquininha.'),
        ('cmd_trans_void', 'Estornar', 'Cancela uma venda já concluída e devolve o valor ao cliente. Só fica ativo depois de uma venda.'),
      ],
    ),
    ..._group(1, 'cmd_info', 'Informações', 'Dados de identificação da maquininha e da conta PagSeguro.', [
      ('cmd_info_user', 'Dono da Maquininha', 'Mostra os dados da conta PagSeguro a quem este equipamento pertence.'),
      ('cmd_info_serial', 'Número de Série', 'Mostra o número de série do aparelho, útil para suporte e identificação.'),
    ]),
    ..._group(1, 'cmd_manage', 'Gerenciamento', 'Ferramentas de manutenção da maquininha.', [
      (
        'cmd_manage_busy',
        'Verificar Serviço',
        'Informa se o serviço PagSeguro está ocupado com outra operação. Use antes de iniciar algo ou se o app parecer travado.',
      ),
      ('cmd_manage_reboot', 'Reiniciar', 'Reinicia a maquininha. Pode resolver travamentos do serviço, mas encerra o app.'),
    ]),
    // ---- Aba Recursos: os passos são gerados a partir de kFeatureSections (features_tab.dart)
    for (final sec in kFeatureSections)
      ..._group(2, 'sec:${sec.title}', sec.title, sec.subtitle, [
        for (final f in sec.features) ('feat:${f.label}', f.label, f.description),
      ]),
    const TourStep(
      2,
      null,
      'Fim do Tour',
      'Pronto! Em Recursos, cada botão mostra uma explicação antes do resultado. '
          'Para rever o tour, toque no botão flutuante "Tour guiado".',
    ),
  ];

  /// Inicia o tour (precisa de um contexto abaixo do DefaultTabController)
  static void start(BuildContext context) {
    final TabController tabs = DefaultTabController.of(context);
    final OverlayState overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _TourOverlay(steps: steps, tabs: tabs, onClose: () => entry.remove()),
    );
    overlay.insert(entry);
  }
}

/// Camada do tour inserida no Overlay: escurece a tela, destaca o componente do passo atual
/// e mostra o cartão com a explicação e os botões de navegação.
class _TourOverlay extends StatefulWidget {
  final List<TourStep> steps;
  final TabController tabs;
  final VoidCallback onClose;

  const _TourOverlay({required this.steps, required this.tabs, required this.onClose});

  @override
  State<_TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<_TourOverlay> {
  int _index = 0;
  Rect? _rect;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _go(0, 1));
  }

  /// Pula os passos do bloco atual e vai ao primeiro passo do próximo bloco
  void _skipBlock() {
    final String? group = widget.steps[_index].group;
    int j = _index + 1;
    while (j < widget.steps.length && widget.steps[j].group == group) {
      j++;
    }
    if (j >= widget.steps.length) {
      widget.onClose();
    } else {
      _go(j, 1);
    }
  }

  /// Vai para o passo [i]; [dir] (+1/-1) define o sentido ao pular passos sem componente na tela
  Future<void> _go(int i, int dir) async {
    while (i >= 0 && i < widget.steps.length) {
      final TourStep step = widget.steps[i];
      setState(() {
        _ready = false;
        _index = i;
      });

      if (widget.tabs.index != step.tab) {
        widget.tabs.animateTo(step.tab);
        await Future<void>.delayed(kTabScrollDuration + const Duration(milliseconds: 150));
        if (!mounted) return;
      }

      if (step.id == null) {
        setState(() {
          _rect = null;
          _ready = true;
        });
        return;
      }

      final BuildContext? target = TourKeys.of(step.id!).currentContext;
      if (target != null && target.mounted) {
        await Scrollable.ensureVisible(target, alignment: 0.4, duration: const Duration(milliseconds: 300));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        if (!mounted || !target.mounted) return;
        final RenderObject? box = target.findRenderObject();
        if (box is RenderBox && box.attached) {
          setState(() {
            _rect = box.localToGlobal(Offset.zero) & box.size;
            _ready = true;
          });
          return;
        }
      }
      i += dir; // componente ausente (ex.: já ativado): pula o passo
    }
    if (mounted) widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final TourStep step = widget.steps[_index];
    final Size screen = MediaQuery.of(context).size;
    final Rect? rect = _ready ? _rect : null;
    final bool below = rect == null || rect.center.dy < screen.height / 2;

    final Widget card = Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (step.group != null && !step.block)
              Text('Bloco: ${step.group}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
            Text(step.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: screen.height * 0.45),
              child: SingleChildScrollView(child: Text(step.text)),
            ),
            if (step.block)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _ready ? _skipBlock : null,
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Pular bloco'),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('${_index + 1}/${widget.steps.length}', style: const TextStyle(fontSize: 12)),
                const Spacer(),
                TextButton(onPressed: widget.onClose, child: const Text('Sair')),
                TextButton(onPressed: _ready && _index > 0 ? () => _go(_index - 1, -1) : null, child: const Text('Anterior')),
                FilledButton(
                  onPressed: _ready ? () => _index == widget.steps.length - 1 ? widget.onClose() : _go(_index + 1, 1) : null,
                  child: Text(_index == widget.steps.length - 1 ? 'Concluir' : 'Próximo'),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Fundo esmaecido com "buraco" no componente; absorve toques para não acionar a tela por baixo
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: CustomPaint(painter: _SpotlightPainter(rect)),
            ),
          ),
          if (_ready)
            Positioned(
              left: 12,
              right: 12,
              top: rect == null ? screen.height * 0.25 : (below ? rect.bottom + 14 : null),
              bottom: rect != null && !below ? screen.height - rect.top + 14 : null,
              child: card,
            ),
        ],
      ),
    );
  }
}

/// Pinta o fundo escuro com um recorte arredondado e uma borda no componente destacado
class _SpotlightPainter extends CustomPainter {
  final Rect? target;

  const _SpotlightPainter(this.target);

  @override
  void paint(Canvas canvas, Size size) {
    final Path dim = Path()..addRect(Offset.zero & size);
    final Rect? t = target?.inflate(6);
    if (t != null) {
      dim.addRRect(RRect.fromRectAndRadius(t, const Radius.circular(12)));
    }
    dim.fillType = PathFillType.evenOdd;
    canvas.drawPath(dim, Paint()..color = Colors.black.withValues(alpha: 0.78));
    if (t != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(t, const Radius.circular(12)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = Colors.amberAccent,
      );
    }
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) => old.target != target;
}
