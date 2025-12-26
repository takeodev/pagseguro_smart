class Constants {
  /// Variáveis para controle de cancelamento
  static const List<String> allowWords = [
    'aproxime',
    'insira',
    'chip',
    'verifique',
    'inserido'
  ];
  static const List<String> denyWords = [
    'retire',
    'tempo',
    'permitida',
    'atualizando',
    'selecionado',
    'senha'
  ];
  static const List<String> allowPhrases = [
    'servico ocupado',
    'nao tente novamente'
  ];
  static const List<String> denyPhrases = [
    'transação autorizada',
    'transação não autorizada',
    'operacao cancelada',
    'operacao nao',
  ];
}

enum PagSeguroEnum {
  /// Tipo de Pagamento não Suportado pela PagSeguro (t = type) para Uso Interno apenas!
  tMoney(0, 'money'),

  /// Tipos de pagamento suportados pela PagSeguro (t = type)
  tCredit(1, 'credit'), // PlugPag.TYPE_CREDITO
  tDebit(2, 'debit'), // PlugPag.TYPE_DEBITO
  tVoucher(3, 'voucher'), // PlugPag.TYPE_VOUCHER
  tQrCode(4, 'qrCode'), // PlugPag.TYPE_QRCODE
  tPix(5, 'pix'), // PlugPag.TYPE_PIX
  tPreAuthCard(7, 'preAuthCard'), // PlugPag.TYPE_PREAUTO_CARD
  tQrCodeCredit(8, 'qrCodeCredit'), // PlugPag.TYPE_QRCODE_CREDITO
  tPreAuthKeyed(9, 'preAuthKeyed'), // PlugPag.TYPE_PREAUTO_KEYED

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
