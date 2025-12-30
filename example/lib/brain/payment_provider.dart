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

class PaymentProvider extends ChangeNotifier {
  final PagSeguroService pagSeguro = PagSeguroService();

  // Ações de Click para Prevenção de Múltiplos Clicks
  bool isTapped = false;
  bool isAbortTapped = false;
  bool isServiceTapped = false;
  bool isStyleTapped = false;

  // Estado da Maquininha ou Pagamento
  bool isActivated = false;
  bool isInProgress = false;
  bool canAbort = false;
  bool isLoading = false;

  // Configurações
  LayoutPreset? actualPreset;
  bool askPrint = true;
  bool smsPrint = false;

  // Dados a Serem Exibidos
  String displayMessage = '';
  String? transactionCode;
  String? transactionId;

  // Listener da Ação de Pagamento
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
  // VERIFICA AUTENTICAÇÃO DO PINPAD
  // ============================================================
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
      final result = await pagSeguro.isAuthenticated();
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
      final result = await pagSeguro.initPinPad(code);
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
        final result = await pagSeguro.doPayment(
          type: payType,
          value: value,
          userReference: 't${payType.code}p123',
          printReceipt: false,
        );

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
  Future<void> abortTransaction() async {
    if (isAbortTapped || !canAbort) return;
    isAbortTapped = true;

    String message = 'Cancelando Transação...';
    displayMessage = message;
    notifyListeners();
    BotToast.showText(text: message);

    try {
      final result = await pagSeguro.abortTransaction();

      while (isInProgress) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      message = (result['success'] ?? false)
          ? 'Transação Cancelada!'
          : result['message'];

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
  Future<void> voidPayment(
    BuildContext context, {
    PagSeguroEnum voidType = PagSeguroEnum.vCommon,
  }) async {
    if (transactionCode == null ||
        transactionId == null ||
        transactionCode!.isEmpty ||
        transactionId!.isEmpty) {
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
      final result = await pagSeguro.voidPayment(
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
  Future<void> getLastTransaction() async {
    if (isTapped) return;
    isTapped = true;

    String message = 'Buscando Última Transação...';
    displayMessage = message;
    isLoading = true;
    notifyListeners();
    BotToast.showText(text: message);

    try {
      final result = await pagSeguro.getLastTransaction();

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
            final result = await pagSeguro.sendReceiptSMS(
              transactionCode: transactionCode!,
              phoneNumber: cel,
            );
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
  Future<void> setPrintActionListener({
    bool askCustomerReceipt = true,
    bool smsReceipt = false,
  }) async {
    if (isTapped) return;
    isTapped = true;

    String message = 'Configurando Recibo do Cliente...';
    displayMessage = message;
    isLoading = true;
    notifyListeners();
    BotToast.showText(text: message);

    try {
      final result = await pagSeguro.setPrintActionListener(
        askCustomerReceipt: askCustomerReceipt,
        smsReceipt: smsReceipt,
      );

      message = result['message'] ?? '';
      askPrint = askCustomerReceipt;
      smsPrint = smsReceipt;
      displayMessage = message;
      BotToast.showText(text: message);
    } catch (e) {
      askPrint = true;
      smsPrint = false;
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
  Future<void> setPlugPagCustomPrinterLayout({
    String? title,
    LayoutPreset? layoutPreset,
    int maxTimeShowPopup = 20,
  }) async {
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
  Future<void> setFullStyleData({
    String? title,
    LayoutPreset? layoutPreset,
    int maxTimeShowPopup = 20,
  }) async {
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
