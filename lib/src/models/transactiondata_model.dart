import 'dart:convert';

/// Modelo de Dados de Transação / Pagamento (PlugPagTransactionResult)
/// Documentação: https://pagseguro.github.io/pagseguro-sdk-plugpagservicewrapper/-wrapper-p-p-s/br.com.uol.pagseguro.plugpagservice.wrapper/-plug-pag-transaction-result/index.html
class TransactionDataModel {
  final String? message;
  final String? errorCode;
  final String? transactionCode;
  final String? transactionId;
  final String? date;
  final String? time;
  final String? hostNsu;
  final String? cardBrand;
  final String? bin;
  final String? holder;
  final String? userReference;
  final String? terminalSerialNumber;
  final String? amount;
  final String? availableBalance;
  final String? cardApplication;
  final String? label;
  final String? holderName;
  final String? extendedHolderName;
  final String? cardIssuerNationality;
  final int? result;
  final String? readerModel;
  final String? nsu;
  final String? autoCode;
  final int? installments;
  final int? originalAmount;
  final String? buyerName;
  final int? paymentType;
  final String? typeTransaction;
  final String? appIdentification;
  final String? cardHash;
  final String? preAutoDueDate;
  final String? preAutoOriginalAmount;
  final int userRegistered;
  final String? accumulatedValue;
  final String? consumerIdentification;
  final String? currentBalance;
  final String? consumerPhoneNumber;
  final String? clubePagScreensIds;
  final String? partialPayPartiallyAuthorizedAmount;
  final String? partialPayRemainingAmount;
  final String? pixTxIdCode;

  const TransactionDataModel({
    this.message,
    this.errorCode,
    this.transactionCode,
    this.transactionId,
    this.date,
    this.time,
    this.hostNsu,
    this.cardBrand,
    this.bin,
    this.holder,
    this.userReference,
    this.terminalSerialNumber,
    this.amount,
    this.availableBalance,
    this.cardApplication,
    this.label,
    this.holderName,
    this.extendedHolderName,
    this.cardIssuerNationality,
    this.result = 0,
    this.readerModel,
    this.nsu,
    this.autoCode,
    this.installments,
    this.originalAmount = 0,
    this.buyerName,
    this.paymentType = 0,
    this.typeTransaction,
    this.appIdentification,
    this.cardHash,
    this.preAutoDueDate,
    this.preAutoOriginalAmount,
    this.userRegistered = 0,
    this.accumulatedValue,
    this.consumerIdentification,
    this.currentBalance,
    this.consumerPhoneNumber,
    this.clubePagScreensIds,
    this.partialPayPartiallyAuthorizedAmount,
    this.partialPayRemainingAmount,
    this.pixTxIdCode,
  });

  /// Construtor vazio
  factory TransactionDataModel.empty() => const TransactionDataModel();

  /// Converte o modelo em JSON
  Map<String, dynamic> toJson() {
    final map = {
      'message': message?.trim(),
      'errorCode': errorCode?.trim(),
      'transactionCode': transactionCode?.trim(),
      'transactionId': transactionId?.trim(),
      'date': date?.trim(),
      'time': time?.trim(),
      'hostNsu': hostNsu?.trim(),
      'cardBrand': cardBrand?.trim(),
      'bin': bin?.trim(),
      'holder': holder?.trim(),
      'userReference': userReference?.trim(),
      'terminalSerialNumber': terminalSerialNumber?.trim(),
      'amount': amount?.trim(),
      'availableBalance': availableBalance?.trim(),
      'cardApplication': cardApplication?.trim(),
      'label': label?.trim(),
      'holderName': holderName?.trim(),
      'extendedHolderName': extendedHolderName?.trim(),
      'cardIssuerNationality': cardIssuerNationality?.trim(),
      'result': result,
      'readerModel': readerModel?.trim(),
      'nsu': nsu?.trim(),
      'autoCode': autoCode?.trim(),
      'installments': installments,
      'originalAmount': originalAmount,
      'buyerName': buyerName?.trim(),
      'paymentType': paymentType,
      'typeTransaction': typeTransaction?.trim(),
      'appIdentification': appIdentification?.trim(),
      'cardHash': cardHash?.trim(),
      'preAutoDueDate': preAutoDueDate?.trim(),
      'preAutoOriginalAmount': preAutoOriginalAmount?.trim(),
      'userRegistered': userRegistered,
      'accumulatedValue': accumulatedValue?.trim(),
      'consumerIdentification': consumerIdentification?.trim(),
      'currentBalance': currentBalance?.trim(),
      'consumerPhoneNumber': consumerPhoneNumber?.trim(),
      'clubePagScreensIds': clubePagScreensIds?.trim(),
      'partialPayPartiallyAuthorizedAmount':
          partialPayPartiallyAuthorizedAmount?.trim(),
      'partialPayRemainingAmount': partialPayRemainingAmount?.trim(),
      'pixTxIdCode': pixTxIdCode?.trim(),
    }..removeWhere((_, value) => value == null || value == '');

    return map;
  }

  /// Cria um modelo a partir de JSON
  factory TransactionDataModel.fromMap(dynamic json) {
    // Se json for null ou não for um Map, retorna modelo vazio
    if (json == null || json is! Map) return TransactionDataModel.empty();

    // Converte Map<Object?, Object?> para Map<String, dynamic>
    final map = Map<String, dynamic>.from(json);

    try {
      return TransactionDataModel(
        message: map['message'] as String?,
        errorCode: map['errorCode'] as String?,
        transactionCode: map['transactionCode'] as String?,
        transactionId: map['transactionId'] as String?,
        date: map['date'] as String?,
        time: map['time'] as String?,
        hostNsu: map['hostNsu'] as String?,
        cardBrand: map['cardBrand'] as String?,
        bin: map['bin'] as String?,
        holder: map['holder'] as String?,
        userReference: map['userReference'] as String?,
        terminalSerialNumber: map['terminalSerialNumber'] as String?,
        amount: map['amount'] as String?,
        availableBalance: map['availableBalance'] as String?,
        cardApplication: map['cardApplication'] as String?,
        label: map['label'] as String?,
        holderName: map['holderName'] as String?,
        extendedHolderName: map['extendedHolderName'] as String?,
        cardIssuerNationality: map['cardIssuerNationality'] as String?,
        result: map['result'] as int? ?? 0,
        readerModel: map['readerModel'] as String?,
        nsu: map['nsu'] as String?,
        autoCode: map['autoCode'] as String?,
        installments: map['installments'] as int?,
        originalAmount: map['originalAmount'] as int? ?? 0,
        buyerName: map['buyerName'] as String?,
        paymentType: map['paymentType'] as int? ?? 0,
        typeTransaction: map['typeTransaction'] as String?,
        appIdentification: map['appIdentification'] as String?,
        cardHash: map['cardHash'] as String?,
        preAutoDueDate: map['preAutoDueDate'] as String?,
        preAutoOriginalAmount: map['preAutoOriginalAmount'] as String?,
        userRegistered: map['userRegistered'] as int? ?? 0,
        accumulatedValue: map['accumulatedValue'] as String?,
        consumerIdentification: map['consumerIdentification'] as String?,
        currentBalance: map['currentBalance'] as String?,
        consumerPhoneNumber: map['consumerPhoneNumber'] as String?,
        clubePagScreensIds: map['clubePagScreensIds'] as String?,
        partialPayPartiallyAuthorizedAmount:
            map['partialPayPartiallyAuthorizedAmount'] as String?,
        partialPayRemainingAmount: map['partialPayRemainingAmount'] as String?,
        pixTxIdCode: map['pixTxIdCode'] as String?,
      );
    } catch (_) {
      return TransactionDataModel.empty();
    }
  }

  String toJsonString() => jsonEncode(toJson());
}
