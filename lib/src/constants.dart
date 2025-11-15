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

class PagSeguroType {
  /// Tipos de pagamento suportados pela PagSeguro
  static const int credit = 1; // PlugPag.TYPE_CREDITO
  static const int debit = 2; // PlugPag.TYPE_DEBITO
  static const int voucher = 3; // PlugPag.TYPE_VOUCHER
  static const int qrCode = 4; // PlugPag.TYPE_QRCODE
  static const int pix = 5; // PlugPag.TYPE_PIX
  static const int preAuthCard = 7; // PlugPag.TYPE_PREAUTO_CARD
  static const int qrCodeCredit = 8; // PlugPag.TYPE_QRCODE_CREDITO
  static const int preAuthKeyed = 9; // PlugPag.TYPE_PREAUTO_KEYED
}

class PagSeguroInstallment {
  /// Tipos de parcelamento suportados pela PagSeguro
  static const int singlePay = 1; // PlugPag.INSTALLMENT_TYPE_A_VISTA
  static const int forMerchant = 2; // PlugPag.INSTALLMENT_TYPE_PARC_VENDEDOR
  static const int forCustomer = 3; // PlugPag.INSTALLMENT_TYPE_PARC_COMPRADOR
}

class PagSeguroVoid {
  /// Tipos de estorno suportados pela PagSeguro
  static const int common = 1; // PlugPag.VOID_PAYMENT
  static const int qrCode = 2; // PlugPag.VOID_QRCODE
}
