import 'package:flutter/material.dart';

/// ======================================================================================
/// Arquivo         : utils/dialog_helper.dart
/// Projeto         : PagSeguro Smart
/// Plataforma      : Android
/// Equipamentos    : Modelos de Maquininhas PagSeguro testados - P2 A7, P2 A11 & GPOS A11
/// Autor           : Fernando Takeo Miyaji
/// ======================================================================================

/// Área rolável para conteúdo de janelas. Deixa claro que há mais conteúdo: barra de rolagem sempre
/// visível e, enquanto existir conteúdo abaixo, um degradê com o aviso "Role para ver mais" (some ao chegar no fim).
/// Evita que a pessoa toque em "Entendi" sem ter lido tudo.
class ScrollHintBox extends StatefulWidget {
  final double maxHeight;
  final Widget child;

  const ScrollHintBox({super.key, required this.maxHeight, required this.child});

  @override
  State<ScrollHintBox> createState() => _ScrollHintBoxState();
}

class _ScrollHintBoxState extends State<ScrollHintBox> {
  final ScrollController _controller = ScrollController();

  /// true enquanto ainda há conteúdo abaixo da área visível
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_update);
    // Depois do 1º layout já se sabe se o conteúdo ultrapassa a altura máxima
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _update() {
    if (!mounted || !_controller.hasClients || !_controller.position.hasContentDimensions) {
      return;
    }
    final bool more = _controller.position.extentAfter > 8;
    if (more != _hasMore) setState(() => _hasMore = more);
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      child: Stack(
        children: [
          Scrollbar(
            controller: _controller,
            thumbVisibility: true,
            child: SingleChildScrollView(controller: _controller, padding: const EdgeInsets.only(right: 12), child: widget.child),
          ),
          if (_hasMore)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  height: 56,
                  alignment: Alignment.bottomCenter,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00FFFFFF), Colors.white],
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Role para ver mais', style: TextStyle(color: Colors.white, fontSize: 13)),
                        SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Janelas padronizadas do Example: folha inferior com título, conteúdo e botões, e botões de ação.
class DialogHelper {
  /// Abre uma folha inferior (bottom sheet) com [title], [content] e [actions].
  /// Com mais de 2 [actions] os botões ficam empilhados em largura total; com até 2, alinhados à direita.
  /// [dismissible] = false impede fechar tocando fora da folha (o usuário precisa usar um botão).
  static Future<T?> showBottom<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
    bool dismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      isDismissible: dismissible,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TÍTULO
                  Padding(
                    padding: const EdgeInsets.only(left: 5, right: 5, bottom: 10),
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87),
                    ),
                  ),

                  // CONTEÚDO
                  Padding(padding: const EdgeInsets.only(bottom: 10), child: content),

                  // BOTÕES
                  if (actions != null && actions.length > 2)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: actions.map((e) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: SizedBox(width: double.infinity, child: e),
                        );
                      }).toList(),
                    ),
                  if (actions != null && actions.length <= 2)
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: actions.map((e) {
                        return Padding(padding: const EdgeInsets.only(left: 8.0), child: e);
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Botão primário (verde) para a ação principal da janela
  static Widget primaryButton(String text, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: onTap,
      child: Text(text),
    );
  }

  /// Botão secundário (texto simples) para ações de cancelar ou fechar
  static Widget secondaryButton(String text, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      child: Text(text, style: const TextStyle(fontSize: 16)),
    );
  }
}
