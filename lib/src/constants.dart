/// Palavras-chave das mensagens da maquininha usadas para liberar ou bloquear o cancelamento
/// (ver `_abortPermission` em PagSeguroService). A comparação é feita com o texto em minúsculas
/// e por "contém", então basta uma parte da mensagem. (Até a 1.3.x se chamava [Constants].)
class PagSeguroConstants {
  /// Mensagens que liberam o cancelamento (ex.: pedir para aproximar, inserir ou verificar o cartão)
  static const List<String> allowWords = ['aproxime', 'insira', 'chip', 'verifique', 'inserido'];
  static const List<String> denyWords = ['retire', 'tempo', 'permitida', 'atualizando', 'selecionado', 'senha'];
  static const List<String> allowPhrases = ['servico ocupado', 'nao tente novamente'];
  static const List<String> denyPhrases = ['transação autorizada', 'transação não autorizada', 'operacao cancelada', 'operacao nao'];
}

/// Nome antigo de [PagSeguroConstants], mantido só para não quebrar quem já usa o pacote.
@Deprecated('Use PagSeguroConstants. Constants será removido em uma versão futura (2.0).')
typedef Constants = PagSeguroConstants;

/// Identificador de Tipos de Pagamento com Cartão
var cardPayments = {PagSeguroEnum.tCredit, PagSeguroEnum.tDebit, PagSeguroEnum.tVoucher};

enum PagSeguroEnum {
  /// Tipo de Pagamento não Suportado pela PagSeguro (t = type) para Uso Interno apenas!
  tMoney(0, 'money'),

  /// Tipos de pagamento suportados pela PagSeguro (t = type)
  tCredit(1, 'credit'), // PlugPag.TYPE_CREDITO
  tDebit(2, 'debit'), // PlugPag.TYPE_DEBITO
  tVoucher(3, 'voucher'), // PlugPag.TYPE_VOUCHER
  tQrCode(4, 'qrCode'), // PlugPag.TYPE_QRCODE
  tPix(5, 'pix'), // PlugPag.TYPE_PIX
  // ATENÇÃO: os códigos abaixo devem ser iguais aos do Wrapper PagSeguro (PlugPag.TYPE_*)
  tPreAuthCard(6, 'preAuthCard'), // PlugPag.TYPE_PREAUTO_CARD
  tQrCodeCredit(7, 'qrCodeCredit'), // PlugPag.TYPE_QRCODE_CREDITO
  tPreAuthKeyed(8, 'preAuthKeyed'), // PlugPag.TYPE_PREAUTO_KEYED

  /// Tipos de parcelamento suportados pela PagSeguro (i = installment type)
  iSinglePay(1, 'singlePay'), // PlugPag.INSTALLMENT_TYPE_A_VISTA
  iForMerchant(2, 'forMerchant'), // PlugPag.INSTALLMENT_TYPE_PARC_VENDEDOR
  iForCustomer(3, 'forCustomer'), // PlugPag.INSTALLMENT_TYPE_PARC_COMPRADOR

  /// Tipos de estorno suportados pela PagSeguro (v = void)
  vCommon(1, 'common'), // PlugPag.VOID_PAYMENT
  vQrCode(2, 'qrCode'); // PlugPag.VOID_QRCODE

  final int code;
  final String description;

  const PagSeguroEnum(this.code, this.description);
}

/// Cores de LED da Maquininha (valores de PlugPagLedData do Wrapper) - 1.4.0
enum PagSeguroLed {
  off(0), // PlugPagLedData.LED_OFF
  red(1), // PlugPagLedData.LED_RED
  green(2), // PlugPagLedData.LED_GREEN
  yellow(4), // PlugPagLedData.LED_YELLOW
  blue(8); // PlugPagLedData.LED_BLUE

  final int code;

  const PagSeguroLed(this.code);
}
