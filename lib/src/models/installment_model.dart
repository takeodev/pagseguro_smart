// ======================================================================================
// Arquivo         : src/models/installment_model.dart
// Projeto         : PagSeguro Smart
// Autor           : Fernando Takeo Miyaji
// ======================================================================================

/// Parcela calculada pelo Wrapper PagSeguro (calculateInstallments com installmentType). - 1.4.0
/// Valores em centavos, como retornados pelo Wrapper.
class InstallmentModel {
  /// Quantidade de parcelas
  final int quantity;

  /// Valor de cada parcela (centavos)
  final int amount;

  /// Valor total (centavos)
  final int total;

  const InstallmentModel({required this.quantity, required this.amount, required this.total});

  /// Valor de cada parcela em Reais
  double get amountValue => amount / 100;

  /// Valor total em Reais
  double get totalValue => total / 100;

  factory InstallmentModel.fromMap(Map<dynamic, dynamic> map) => InstallmentModel(
        quantity: (map['quantity'] as num?)?.toInt() ?? 0,
        amount: (map['amount'] as num?)?.toInt() ?? 0,
        total: (map['total'] as num?)?.toInt() ?? 0,
      );

  /// Converte o "data" de calculateInstallments (`List<Map>`) em lista de modelos
  static List<InstallmentModel> fromList(dynamic data) =>
      (data is List) ? data.whereType<Map>().map(InstallmentModel.fromMap).toList() : <InstallmentModel>[];

  Map<String, dynamic> toMap() => {'quantity': quantity, 'amount': amount, 'total': total};
}
