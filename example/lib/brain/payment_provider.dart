import 'package:bot_toast/bot_toast.dart';
import 'package:example/utils/functions.dart';
import 'package:flutter/material.dart';
import 'package:pagseguro_smart/pagseguro_smart.dart';

/// ======================================================================================
/// Arquivo         : brain/payment_provider.dart
/// Projeto         : PagSeguro Smart
/// Plataforma      : Android
/// Equipamentos    : Modelos de Maquininhas PagSeguro testados - P2 A7, P2 A11 & GPOS A11
/// Autor           : Fernando Takeo Miyaji
/// ======================================================================================

/// Estado e regras do Example (camada de negócio entre as abas e o [PagSeguroService]).
/// Cada ação do App é um método: ele marca o estado (ex.: `isLoading`), chama o plugin, mostra a mensagem
/// (`displayMessage` e BotToast) e avisa a tela com `notifyListeners`. O plugin responde sempre com
/// `{success, message, data}`, usado para decidir o que atualizar.
class PaymentProvider extends ChangeNotifier {
  /// Única instância do plugin usada pelo App. Não crie outra: o canal é compartilhado (ver PagSeguroService).
  final PagSeguroService pagSeguro = PagSeguroService();

  // Ações de Click para Prevenção de Múltiplos Clicks
  // Cada flag é ligada enquanto a ação correspondente roda e impede um segundo clique até terminar
  bool isTapped = false;
  bool isAbortTapped = false;
  bool isServiceTapped = false;
  bool isStyleTapped = false;

  // Estado da Maquininha ou Pagamento
  /// PinPad ativado (libera as ações que usam o plugin)
  bool isActivated = false;

  /// Venda em andamento (entre o início e o fim do doPayment); o botão Cancelar depende disso
  bool isInProgress = false;

  /// Cancelamento liberado pela maquininha (vem do onPaymentProgress do plugin)
  bool canAbort = false;

  /// Indicador de carregamento na tela
  bool isLoading = false;

  // Modo de Execução: Assíncrono (listeners do Wrapper) ou Síncrono
  bool useAsync = false;

  // Configurações do recibo do cliente (espelham o último setPrintActionListener com sucesso)
  LayoutPreset? actualPreset;
  bool askPrint = true;
  bool smsPrint = false;
  bool directPrint = false;

  // Dados a Serem Exibidos
  String displayMessage = '';

  /// Dados da última transação aprovada, usados por estorno e 2ª via (ficam só em memória)
  String? transactionCode;
  String? transactionId;

  // Listener da Ação de Pagamento
  // Mensagens de progresso da maquininha: mostra na tela e atualiza se o cancelamento está liberado
  PaymentProvider() {
    pagSeguro.onPaymentProgress = (msg, abort) {
      bool hasChange = false;
      BotToast.showText(text: msg);

      if (displayMessage != msg) hasChange = true;
      displayMessage = msg;

      if (canAbort != abort) {
        canAbort = abort;
        hasChange = true;
      }

      if (hasChange) {
        notifyListeners();
      }
    };
  }

  // ============================================================
  // MODO DE EXECUÇÃO (SÍNCRONO / ASSÍNCRONO)
  // ============================================================
  /// Liga/desliga o modo assíncrono. Não muda nada durante uma operação em andamento.
  void setUseAsync(bool value) {
    if (isInProgress || isLoading) return;
    useAsync = value;
    notifyListeners();
  }

  // ============================================================
  // VERIFICA AUTENTICAÇÃO DO PINPAD
  // ============================================================
  /// Consulta se o PinPad está ativado. Atualiza `isActivated`, que decide se a aba mostra
  /// o campo de ativação ou os pagamentos. Retorna o mesmo valor.
  Future<bool> isAuthenticated() async {
    if (isTapped) return false;
    isTapped = true;

    String message = 'Verificando PinPad...';
    displayMessage = message;
    isActivated = false;
    isLoading = true;
    notifyListeners();

    BotToast.showText(text: message);

    try {
      final result = await (useAsync ? pagSeguro.asyncIsAuthenticated() : pagSeguro.isAuthenticated());
      message = result['message'] ?? '';
      isActivated = result['success'];
      displayMessage = message;
      BotToast.showText(text: message);
    } catch (e) {
      message = 'Erro ao Verificar PinPad!';
      displayMessage = '$message\n$e';
      BotToast.showText(text: message);
    } finally {
      isLoading = false;
      isTapped = false;
      notifyListeners();
    }
    return isActivated;
  }

  // ============================================================
  // ATIVAR PINPAD
  // ============================================================
  /// Ativa o PinPad com [code] (código de ativação digitado na aba Pagamento). Código vazio é recusado sem chamar o plugin.
  Future<void> activatePinPad(String code) async {
    if (code.isEmpty) {
      BotToast.showText(text: 'Informe o Código de Ativação');
      return;
    }

    if (isTapped) return;
    isTapped = true;

    String message = 'Ativando PinPad...';
    displayMessage = message;
    isLoading = true;
    notifyListeners();

    BotToast.showText(text: message);

    try {
      final result = await (useAsync ? pagSeguro.asyncInitPinPad(code) : pagSeguro.initPinPad(code));
      message = result['message'] ?? '';
      isActivated = result['success'];
      displayMessage = message;
      BotToast.showText(text: message);
    } catch (e) {
      message = 'Erro ao Ativar PinPad!';
      displayMessage = '$message\n$e';
      BotToast.showText(text: message);
    } finally {
      isLoading = false;
      isTapped = false;
      notifyListeners();
    }
  }

  // ============================================================
  // DADOS DO USUÁRIO
  // ============================================================
  /// Busca os dados do dono da maquininha e mostra em uma janela. Atenção LGPD: são dados pessoais, não logar.
  Future<void> getUserData(BuildContext context) async {
    if (isTapped) return;
    isTapped = true;

    String message = 'Buscando Dados do Usuário...';
    displayMessage = message;
    isLoading = true;
    notifyListeners();
    BotToast.showText(text: message);

    try {
      final result = await pagSeguro.getUserData();

      if (result['success'] && context.mounted) {
        final model = UserDataModel.fromMap(result['data']);
        await userDialog(context, model);
      }

      message = result['message'] ?? '';
      displayMessage = message;
      BotToast.showText(text: message);
    } catch (e) {
      message = 'Erro ao Buscar Dados!';
      displayMessage = '$message\n$e';
      BotToast.showText(text: message);
    } finally {
      isLoading = false;
      isTapped = false;
      notifyListeners();
    }
  }

  // ============================================================
  // NÚMERO DE SÉRIE
  // ============================================================
  /// Busca o número de série e mostra em uma janela.
  Future<void> getSerialNumber(BuildContext context) async {
    if (isTapped) return;
    isTapped = true;

    String message = 'Buscando Número de Série...';
    displayMessage = message;
    isLoading = true;
    notifyListeners();
    BotToast.showText(text: message);

    try {
      final result = await pagSeguro.getSerialNumber();

      if (result['success'] && context.mounted) {
        await serialDialog(context, result['data']);
      }

      message = result['message'] ?? '';
      displayMessage = message;
      BotToast.showText(text: message);
    } catch (e) {
      message = 'Erro ao Buscar Número de Série!';
      displayMessage = '$message\n$e';
    } finally {
      isLoading = false;
      isTapped = false;
      notifyListeners();
    }
  }

  // ============================================================
  // REINICIAR DISPOSITIVO
  // ============================================================
  /// Pede confirmação ao operador e, se confirmado, reinicia a maquininha.
  Future<void> rebootDevice(BuildContext context) async {
    if (isTapped) return;
    isTapped = true;

    String message = 'Reiniciando Maquininha...';
    displayMessage = message;
    isLoading = true;
    notifyListeners();
    BotToast.showText(text: message);

    try {
      final reboot = await rebootDialog(context);
      if (reboot) {
        final result = await pagSeguro.rebootDevice();
        message = result['message']!;
      } else {
        message = 'Cancelada Reinicialização';
      }
      displayMessage = message;
      BotToast.showText(text: message);
    } catch (e) {
      message = 'Erro ao Reiniciar!';
      displayMessage = '$message\n$e';
    } finally {
      isLoading = false;
      isTapped = false;
      notifyListeners();
    }
  }

  // ============================================================
  // VERIFICADOR DE SERVIÇO
  // ============================================================
  /// Consulta se o serviço PagSeguro está ocupado. Retorna `true` (ocupado) por padrão se a consulta falhar,
  /// para não sugerir que o serviço está livre sem confirmação.
  Future<bool> isServiceBusy() async {
    bool isBusy = true;
    if (isServiceTapped) return isBusy;
    isServiceTapped = true;

    String message = 'Verificando Serviço...';
    displayMessage = message;
    isLoading = true;
    notifyListeners();
    BotToast.showText(text: message);

    try {
      final result = await pagSeguro.isServiceBusy();
      message = result['message']!;
      isBusy = result['data'] ?? true;
      displayMessage = message;
      BotToast.showText(text: message);
    } catch (e) {
      message = 'Erro ao Verificar Serviço!';
      displayMessage = '$message\n$e';
    } finally {
      isLoading = false;
      isServiceTapped = false;
      notifyListeners();
    }

    return isBusy;
  }

  // ============================================================
  // ESTILO DE JANELAS PAGSEGURO
  // ============================================================
  /// Aplica as cores de [layoutPreset] às janelas da maquininha (sem o recibo). `null` envia cores vazias.
  Future<void> setStyleData(LayoutPreset? layoutPreset) async {
    if (isTapped) return;
    isTapped = true;

    String message = 'Definindo Estilo...';
    displayMessage = message;
    isLoading = true;
    notifyListeners();
    BotToast.showText(text: message);
    final StyleDataModel? style = LayoutPresets.of(layoutPreset);

    try {
      final result = await pagSeguro.setStyleData(
        headTextColor: style?.headTextColor,
        headBackgroundColor: style?.headBackgroundColor,
        contentTextColor: style?.contentTextColor,
        contentTextValue1Color: style?.contentTextValue1Color,
        contentTextValue2Color: style?.contentTextValue2Color,
        positiveButtonTextColor: style?.positiveButtonTextColor,
        positiveButtonBackground: style?.positiveButtonBackground,
        negativeButtonTextColor: style?.negativeButtonTextColor,
        negativeButtonBackground: style?.negativeButtonBackground,
        genericButtonBackground: style?.genericButtonBackground,
        genericButtonTextColor: style?.genericButtonTextColor,
        genericSmsEditTextBackground: style?.genericSmsEditTextBackground,
        genericSmsEditTextTextColor: style?.genericSmsEditTextTextColor,
        lineColor: style?.lineColor,
      );
      message = result['message']!;
      actualPreset = layoutPreset;
      displayMessage = message;
      BotToast.showText(text: message);
    } catch (e) {
      actualPreset = null;
      message = 'Erro ao Definir Estilo!';
      displayMessage = '$message\n$e';
    } finally {
      isLoading = false;
      isTapped = false;
      notifyListeners();
    }
  }

  // ============================================================
  // REALIZAR PAGAMENTO
  // ============================================================
  /// Realiza uma venda de [value] (em Reais, mínimo R$ 1,00). Antes, o operador escolhe a forma de
  /// pagamento (crédito, débito, PIX...) em um diálogo; cancelar o diálogo encerra sem chamar o plugin.
  /// Usa `doAsyncPayment` ou `doPayment` conforme [useAsync] e guarda o código da transação para estorno.
  Future<void> doPayment(BuildContext context, double value) async {
    if (value < 1) {
      BotToast.showText(text: 'Valor Mínimo de R\$1,00');
      return;
    }
    if (isTapped) return;
    isTapped = true;

    String message = 'Realizando Pagamento...';
    displayMessage = message;
    isLoading = true;
    isInProgress = true;
    canAbort = false;
    notifyListeners();

    BotToast.showText(text: message);

    PagSeguroEnum? payType = await payMethodDialog(context);

    try {
      if (payType == null || payType.code == 0) {
        message = 'Cancelado Pagamento';
        displayMessage = message;
        BotToast.showText(text: message);
      } else {
        final result = useAsync
            ? await pagSeguro.doAsyncPayment(type: payType, value: value, userReference: 't${payType.code}p123', printReceipt: false)
            : await pagSeguro.doPayment(type: payType, value: value, userReference: 't${payType.code}p123', printReceipt: false);

        if (!isAbortTapped) {
          final model = TransactionDataModel.fromMap(result['data']);
          transactionCode = model.transactionCode;
          transactionId = model.transactionId;
          message = result['message'] ?? '';
          displayMessage = message;
          BotToast.showText(text: message);
          canAbort = false;
        }
      }
    } catch (e) {
      message = 'Erro ao Realizar Pagamento!';
      displayMessage = '$message\n$e';
      BotToast.showText(text: message);
    } finally {
      isLoading = false;
      isInProgress = false;
      isTapped = false;
      notifyListeners();
    }
  }

  // ============================================================
  // ABORTAR TRANSAÇÃO
  // ============================================================
  /// Pede o cancelamento da venda em andamento. Só funciona se `canAbort` (maquininha liberou).
  /// Depois do pedido, espera `isInProgress` virar false (a venda termina) antes de mostrar o resultado final.
  Future<void> abortTransaction() async {
    if (isAbortTapped || !canAbort) return;
    isAbortTapped = true;

    String message = 'Cancelando Transação...';
    displayMessage = message;
    notifyListeners();
    BotToast.showText(text: message);

    try {
      final result = await (useAsync ? pagSeguro.asyncAbortTransaction() : pagSeguro.abortTransaction());

      while (isInProgress) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      message = (result['success'] ?? false) ? 'Transação Cancelada!' : result['message'];

      displayMessage = message;
      BotToast.showText(text: message);
    } catch (e) {
      message = 'Erro ao Cancelar!';
      displayMessage = '$message\n$e';
      BotToast.showText(text: message);
    } finally {
      isAbortTapped = false;
      canAbort = false;
      notifyListeners();
    }
  }

  // ============================================================
  // ESTORNAR TRANSAÇÃO
  // ============================================================
  /// Estorna a última transação guardada em [transactionCode]/[transactionId]. O operador escolhe se quer
  /// imprimir o recibo do estorno. Em caso de sucesso, limpa os códigos (o botão Estornar é desabilitado).
  Future<void> voidPayment(BuildContext context, {PagSeguroEnum voidType = PagSeguroEnum.vCommon}) async {
    if (transactionCode == null || transactionId == null || transactionCode!.isEmpty || transactionId!.isEmpty) {
      BotToast.showText(text: 'Não Identificada Última Transação');
      return;
    }

    if (isTapped) return;
    isTapped = true;

    String message = 'Iniciando Estorno...';
    displayMessage = message;
    isLoading = true;
    isInProgress = true;
    canAbort = false;
    notifyListeners();

    BotToast.showText(text: message);

    bool printReceipt = await voidDialog(context);

    try {
      final result = await (useAsync ? pagSeguro.asyncVoidPayment : pagSeguro.voidPayment)(
        transactionCode: transactionCode!,
        transactionId: transactionId!,
        printReceipt: printReceipt,
        voidType: voidType,
      );

      message = result['message'] ?? '';

      if (!isAbortTapped) {
        if (result['success'] ?? false) {
          transactionCode = null;
          transactionId = null;
        }
        displayMessage = message;
        BotToast.showText(text: message);
      }
    } catch (e) {
      message = 'Erro ao Realizar Estorno!';
      displayMessage = '$message\n$e';
      BotToast.showText(text: message);
    } finally {
      isLoading = false;
      isInProgress = false;
      isTapped = false;
      notifyListeners();
    }
  }

  // ============================================================
  // OBTER CÓDIGO DA ÚLTIMA TRANSAÇÃO
  // ============================================================
  /// Busca a última transação aprovada na maquininha e guarda seus códigos para estorno e 2ª via.
  Future<void> getLastTransaction() async {
    if (isTapped) return;
    isTapped = true;

    String message = 'Buscando Última Transação...';
    displayMessage = message;
    isLoading = true;
    notifyListeners();
    BotToast.showText(text: message);

    try {
      final result = await (useAsync ? pagSeguro.asyncGetLastTransaction() : pagSeguro.getLastTransaction());

      final model = TransactionDataModel.fromMap(result['data']);
      transactionCode = model.transactionCode;
      transactionId = model.transactionId;

      message = result['message']!;
      displayMessage = message;
      BotToast.showText(text: message);
    } catch (e) {
      message = 'Erro ao Buscar Última Transação!';
      displayMessage = '$message\n$e';
    } finally {
      isLoading = false;
      isTapped = false;
      notifyListeners();
    }
  }

  // ============================================================
  // REIMPRESSÃO DE RECIBO
  // ============================================================
  /// 2ª via do recibo da última transação. O operador escolhe via do cliente, via da loja ou SMS
  /// (para SMS, digita o celular). Atenção LGPD: o telefone é dado pessoal, usado só para o envio.
  Future<void> reprintReceipt(BuildContext context) async {
    if (transactionCode == null || transactionCode!.trim().isEmpty) {
      BotToast.showText(text: 'Não Identificada Última Transação');
      return;
    }

    if (isTapped) return;
    isTapped = true;

    String message = 'Reimprimindo Via...';
    displayMessage = message;
    isLoading = true;
    notifyListeners();
    BotToast.showText(text: message);

    try {
      final printReceipt = await receiptDialog(context);

      if (printReceipt.isEmpty) {
        message = 'Cancelada Reimpressão';
      } else {
        if (printReceipt == 'sms') {
          String? cel;

          if (context.mounted) {
            cel = await celPhoneDialog(context);
          }

          if (cel == null || cel.isEmpty) {
            message = 'Cancelado Recibo via SMS';
          } else {
            final result = await pagSeguro.sendReceiptSMS(transactionCode: transactionCode!, phoneNumber: cel);
            message = result['message']!;
          }
        } else {
          final result = (printReceipt == 'customer')
              ? await pagSeguro.reprintCustomerReceipt()
              : await pagSeguro.reprintEstablishmentReceipt();
          message = result['message']!;
        }
      }
      displayMessage = message;
      BotToast.showText(text: message);
    } catch (e) {
      message = 'Erro ao Reimprimir!';
      displayMessage = '$message\n$e';
    } finally {
      isLoading = false;
      isTapped = false;
      notifyListeners();
    }
  }

  // ============================================================
  // CONFIGURAR IMPRESSÃO DE RECIBO DO CLIENTE
  // ============================================================
  /// Define o que fazer com o recibo do cliente ao fim de cada venda. Os campos `askPrint`, `smsPrint` e
  /// `directPrint` só recebem o valor pedido quando o plugin responde `success: true` (senão mantêm o estado anterior).
  Future<void> setPrintActionListener({bool askReceipt = true, bool smsReceipt = false, bool directReceipt = false}) async {
    if (isTapped) return;
    isTapped = true;

    String message = 'Configurando Recibo do Cliente...';
    displayMessage = message;
    isLoading = true;
    notifyListeners();
    BotToast.showText(text: message);

    try {
      final result = await pagSeguro.setPrintActionListener(askReceipt: askReceipt, smsReceipt: smsReceipt, directReceipt: directReceipt);

      message = result['message'] ?? '';
      // Só atualiza o estado exibido se o plugin confirmou; em falha mantém o último estado válido
      if (result['success'] == true) {
        askPrint = askReceipt;
        smsPrint = smsReceipt;
        directPrint = directReceipt;
      }
      displayMessage = message;
      BotToast.showText(text: message);
    } catch (e) {
      // Exceção: o estado real é desconhecido, então não altera o que a tela mostra
      message = 'Erro ao Configurar Recibo do Cliente!';
      displayMessage = '$message\n$e';
    } finally {
      isLoading = false;
      isTapped = false;
      notifyListeners();
    }
  }

  // ============================================================
  // ESTILO DO RECIBO DO CLIENTE
  // ============================================================
  /// Aplica só o estilo do recibo impresso (título, cores e tempo do popup em [maxTimeShowPopup]).
  Future<void> setPlugPagCustomPrinterLayout({String? title, LayoutPreset? layoutPreset, int maxTimeShowPopup = 20}) async {
    if (isTapped) return;
    isTapped = true;

    String message = 'Definindo Estilo do Recibo...';
    displayMessage = message;
    isLoading = true;
    notifyListeners();
    BotToast.showText(text: message);
    final StyleDataModel? style = LayoutPresets.of(layoutPreset);

    try {
      final result = await pagSeguro.setPlugPagCustomPrinterLayout(
        title: title,
        titleColor: style?.headTextColor,
        confirmTextColor: style?.positiveButtonTextColor,
        cancelTextColor: style?.negativeButtonTextColor,
        windowBackgroundColor: style?.headBackgroundColor,
        buttonBackgroundColor: style?.positiveButtonBackground,
        buttonBackgroundColorDisabled: style?.negativeButtonBackground,
        sendSMSTextColor: style?.genericSmsEditTextTextColor,
        maxTimeShowPopup: maxTimeShowPopup,
      );
      message = result['message']!;
      displayMessage = message;
      BotToast.showText(text: message);
    } catch (e) {
      message = 'Erro ao Definir Estilo do Recibo!';
      displayMessage = '$message\n$e';
    } finally {
      isLoading = false;
      isTapped = false;
      notifyListeners();
    }
  }

  // ============================================================
  // ESTILO DE JANELAS PAGSEGURO & JANELA DE RECIBO
  // ============================================================
  /// Aplica o tema completo: primeiro as janelas (`setStyleData`) e, só se der certo, o recibo
  /// (`setPlugPagCustomPrinterLayout`). Usado pelos botões de layout da aba Comandos.
  Future<void> setFullStyleData({String? title, LayoutPreset? layoutPreset, int maxTimeShowPopup = 20}) async {
    if (isStyleTapped) return;
    isStyleTapped = true;

    String message = 'Definindo Estilo Completo...';
    displayMessage = message;
    isLoading = true;
    notifyListeners();
    BotToast.showText(text: message);
    final StyleDataModel? style = LayoutPresets.of(layoutPreset);

    try {
      final result1 = await pagSeguro.setStyleData(
        headTextColor: style?.headTextColor,
        headBackgroundColor: style?.headBackgroundColor,
        contentTextColor: style?.contentTextColor,
        contentTextValue1Color: style?.contentTextValue1Color,
        contentTextValue2Color: style?.contentTextValue2Color,
        positiveButtonTextColor: style?.positiveButtonTextColor,
        positiveButtonBackground: style?.positiveButtonBackground,
        negativeButtonTextColor: style?.negativeButtonTextColor,
        negativeButtonBackground: style?.negativeButtonBackground,
        genericButtonBackground: style?.genericButtonBackground,
        genericButtonTextColor: style?.genericButtonTextColor,
        genericSmsEditTextBackground: style?.genericSmsEditTextBackground,
        genericSmsEditTextTextColor: style?.genericSmsEditTextTextColor,
        lineColor: style?.lineColor,
      );
      message = result1['message']!;
      actualPreset = layoutPreset;
      displayMessage = message;
      BotToast.showText(text: message);

      final bool success = result1['success'] ?? false;
      if (success) {
        final result2 = await pagSeguro.setPlugPagCustomPrinterLayout(
          title: title,
          titleColor: style?.headTextColor,
          confirmTextColor: style?.positiveButtonTextColor,
          cancelTextColor: style?.negativeButtonTextColor,
          windowBackgroundColor: style?.headBackgroundColor,
          buttonBackgroundColor: style?.positiveButtonBackground,
          buttonBackgroundColorDisabled: style?.negativeButtonBackground,
          sendSMSTextColor: style?.genericSmsEditTextTextColor,
          maxTimeShowPopup: maxTimeShowPopup,
        );
        message = result2['message']!;
        displayMessage = message;
        BotToast.showText(text: message);
      }
    } catch (e) {
      actualPreset = null;
      message = 'Erro ao Definir Estilo Completo!';
      displayMessage = '$message\n$e';
    } finally {
      isLoading = false;
      isStyleTapped = false;
      notifyListeners();
    }
  }
}
