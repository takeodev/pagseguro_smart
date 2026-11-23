import 'package:example/brain/payment_provider.dart';
import 'package:example/ui/app_tour.dart';
import 'package:flutter/material.dart';
import 'package:pagseguro_smart/pagseguro_smart.dart';
import 'package:provider/provider.dart';

/// ======================================================================================
/// Arquivo         : ui/commands_tab.dart
/// Projeto         : PagSeguro Smart
/// Plataforma      : Android
/// Equipamentos    : Modelos de Maquininhas PagSeguro testados - P2 A7, P2 A11 & GPOS A11
/// Autor           : Fernando Takeo Miyaji
/// ======================================================================================

/// Aba "Comandos" do Example: modo síncrono/assíncrono, layouts, recibo do cliente, transações,
/// informações e gerenciamento. Cada botão fica habilitado só quando a ação faz sentido no estado atual.
class CommandsTab extends StatelessWidget {
  const CommandsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final PaymentProvider payProv = context.watch<PaymentProvider>();
    // Tempo (maxTimeShowPopup) do popup do recibo ao trocar o layout; mesmo valor usado em main_screen
    final int receiptTimeout = 15;
    final String receiptTitle = 'Recibo PagSeguro Smart';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 110), // folga embaixo para os botões flutuantes
      child: Column(
        children: [
          // MODO DE EXECUÇÃO
          Card(
            key: TourKeys.of('cmd_async'),
            child: SwitchListTile(
              title: const Text('Modo Assíncrono', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: const Text(
                'Desligado (síncrono): simples, o plugin espera o resultado. '
                'Ligado (assíncrono): o Wrapper responde por listeners; ideal para pagamentos. Veja o Tour para detalhes.',
              ),
              value: payProv.useAsync,
              onChanged: payProv.isInProgress || payProv.isLoading ? null : payProv.setUseAsync,
            ),
          ),

          // CONFIGURAÇÕES DE LAYOUT
          Card(
            key: TourKeys.of('cmd_layout'),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  const Text('Configurações de Cores / Layouts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  Wrap(
                    spacing: 5,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        key: TourKeys.of('cmd_layout_pagseguro'),
                        icon: const Icon(Icons.color_lens_rounded),
                        onPressed: payProv.isActivated && payProv.actualPreset != LayoutPreset.pagSeguro
                            ? () => payProv.setFullStyleData(
                                title: receiptTitle,
                                layoutPreset: LayoutPreset.pagSeguro,
                                maxTimeShowPopup: receiptTimeout,
                              )
                            : null,
                        label: const Text('PagSeguro'),
                      ),
                      ElevatedButton.icon(
                        key: TourKeys.of('cmd_layout_blue'),
                        icon: const Icon(Icons.colorize),
                        onPressed: payProv.isActivated && payProv.actualPreset != LayoutPreset.darkBlue
                            ? () => payProv.setFullStyleData(
                                title: receiptTitle,
                                layoutPreset: LayoutPreset.darkBlue,
                                maxTimeShowPopup: receiptTimeout,
                              )
                            : null,
                        label: const Text('Azul'),
                      ),
                      ElevatedButton.icon(
                        key: TourKeys.of('cmd_layout_green'),
                        icon: const Icon(Icons.border_color),
                        onPressed: payProv.isActivated && payProv.actualPreset != LayoutPreset.darkGreen
                            ? () => payProv.setFullStyleData(
                                title: receiptTitle,
                                layoutPreset: LayoutPreset.darkGreen,
                                maxTimeShowPopup: receiptTimeout,
                              )
                            : null,
                        label: const Text('Verde'),
                      ),
                      ElevatedButton.icon(
                        key: TourKeys.of('cmd_layout_sunset'),
                        icon: const Icon(Icons.invert_colors_on),
                        onPressed: payProv.isActivated && payProv.actualPreset != LayoutPreset.warmSunset
                            ? () => payProv.setFullStyleData(
                                title: receiptTitle,
                                layoutPreset: LayoutPreset.warmSunset,
                                maxTimeShowPopup: receiptTimeout,
                              )
                            : null,
                        label: const Text('Por do Sol'),
                      ),
                      ElevatedButton.icon(
                        key: TourKeys.of('cmd_layout_light'),
                        icon: const Icon(Icons.format_color_fill),
                        onPressed: payProv.isActivated && payProv.actualPreset != LayoutPreset.lightCustom
                            ? () => payProv.setFullStyleData(
                                title: receiptTitle,
                                layoutPreset: LayoutPreset.lightCustom,
                                maxTimeShowPopup: receiptTimeout,
                              )
                            : null,
                        label: const Text('Suave / Leve'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // CONFIGURAÇÕES RECIBO CLIENTE (só uma opção fica ativa por vez; a ativa fica desabilitada)
          Card(
            key: TourKeys.of('cmd_receipt'),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  const Text('Configuração de Recibo do Cliente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  Wrap(
                    spacing: 5,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        key: TourKeys.of('cmd_receipt_ask'),
                        icon: const Icon(Icons.question_mark_rounded),
                        onPressed: payProv.isActivated && !payProv.askPrint ? () => payProv.setPrintActionListener(askReceipt: true) : null,
                        label: const Text('Perguntar'),
                      ),
                      ElevatedButton.icon(
                        key: TourKeys.of('cmd_receipt_sms'),
                        icon: const Icon(Icons.sms_outlined),
                        onPressed: payProv.isActivated && !payProv.smsPrint
                            // askReceipt: false é obrigatório: no Android "perguntar" tem prioridade sobre SMS e direto
                            ? () => payProv.setPrintActionListener(askReceipt: false, smsReceipt: true)
                            : null,
                        label: const Text('Via SMS'),
                      ),
                      ElevatedButton.icon(
                        key: TourKeys.of('cmd_receipt_direct'),
                        icon: const Icon(Icons.mark_chat_read_rounded),
                        onPressed: payProv.isActivated && !payProv.directPrint
                            // askReceipt: false é obrigatório: no Android "perguntar" tem prioridade sobre SMS e direto
                            ? () => payProv.setPrintActionListener(askReceipt: false, directReceipt: true)
                            : null,
                        label: const Text('Direto'),
                      ),
                      ElevatedButton.icon(
                        key: TourKeys.of('cmd_receipt_none'),
                        icon: const Icon(Icons.print_disabled),
                        // Habilitado enquanto algum modo de recibo estiver ligado (perguntar, SMS ou direto)
                        onPressed: payProv.isActivated && (payProv.askPrint || payProv.smsPrint || payProv.directPrint)
                            ? () => payProv.setPrintActionListener(askReceipt: false, smsReceipt: false, directReceipt: false)
                            : null,
                        label: const Text('Sem Recibo'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // TRANSACOES
          Card(
            key: TourKeys.of('cmd_trans'),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  const Text('Transações', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  Wrap(
                    spacing: 5,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        key: TourKeys.of('cmd_trans_reprint'),
                        icon: const Icon(Icons.receipt_long),
                        onPressed: payProv.isActivated && payProv.transactionCode != null ? () => payProv.reprintReceipt(context) : null,
                        label: const Text('2ª Via Recibo'),
                      ),
                      ElevatedButton.icon(
                        key: TourKeys.of('cmd_trans_last'),
                        icon: const Icon(Icons.history),
                        onPressed: payProv.isActivated ? payProv.getLastTransaction : null,
                        label: const Text('Última Transação'),
                      ),
                      ElevatedButton.icon(
                        key: TourKeys.of('cmd_trans_void'),
                        icon: const Icon(Icons.undo),
                        onPressed: payProv.isActivated && payProv.transactionCode != null && payProv.transactionId != null
                            ? () => payProv.voidPayment(context)
                            : null,
                        label: const Text('Estornar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // INFORMAÇÕES
          Card(
            key: TourKeys.of('cmd_info'),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  const Text('Informações', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  Wrap(
                    spacing: 5,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        key: TourKeys.of('cmd_info_user'),
                        icon: const Icon(Icons.person_pin),
                        onPressed: payProv.isActivated ? () => payProv.getUserData(context) : null,
                        label: const Text('Dono da Maquininha'),
                      ),
                      ElevatedButton.icon(
                        key: TourKeys.of('cmd_info_serial'),
                        icon: const Icon(Icons.qr_code_2),
                        onPressed: payProv.isActivated ? () => payProv.getSerialNumber(context) : null,
                        label: const Text('Número de Série'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // DISPOSITIVO
          Card(
            key: TourKeys.of('cmd_manage'),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  const Text('Gerenciamento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  Wrap(
                    spacing: 5,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        key: TourKeys.of('cmd_manage_busy'),
                        icon: const Icon(Icons.remove_red_eye),
                        onPressed: payProv.isActivated ? payProv.isServiceBusy : null,
                        label: const Text('Verificar Serviço'),
                      ),
                      ElevatedButton.icon(
                        key: TourKeys.of('cmd_manage_reboot'),
                        icon: const Icon(Icons.restart_alt),
                        onPressed: !payProv.isInProgress && !payProv.isLoading ? () => payProv.rebootDevice(context) : null,
                        label: const Text('Reiniciar'),
                      ),
                    ],
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
