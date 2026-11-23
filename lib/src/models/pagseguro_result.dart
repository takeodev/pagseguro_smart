// ======================================================================================
// Arquivo         : src/models/pagseguro_result.dart
// Projeto         : PagSeguro Smart
// Autor           : Fernando Takeo Miyaji
// ======================================================================================

/// Resultado tipado (opcional) das chamadas do plugin. - 1.4.0
///
/// Todos os métodos do [PagSeguroService] continuam devolvendo `Map<String, dynamic>` no padrão
/// `{success, message, data}` (nada muda para quem já usa o pacote). Esta classe só facilita a leitura:
///
/// ```dart
/// final PagSeguroResult result = (await pagSeguro.getModel()).toPagSeguroResult();
/// if (result.success) print(result.data);
/// ```
class PagSeguroResult {
  /// `true` quando a operação terminou com sucesso
  final bool success;

  /// Mensagem pronta para exibir (sucesso ou motivo da falha)
  final String message;

  /// Dados devolvidos pela operação (tipo varia conforme o método; pode ser `null`)
  final dynamic data;

  const PagSeguroResult({required this.success, required this.message, this.data});

  /// Converte o `Map` devolvido pelo plugin. Campos ausentes viram `success: false` e `message: ''`.
  factory PagSeguroResult.fromMap(Map<dynamic, dynamic> map) =>
      PagSeguroResult(success: map['success'] == true, message: (map['message'] ?? '').toString(), data: map['data']);

  /// Volta para o formato `{success, message, data}`
  Map<String, dynamic> toMap() => {'success': success, 'message': message, 'data': data};

  /// Não inclui [data] de propósito: pode conter dados pessoais ou do cartão (LGPD) e acabar em logs.
  @override
  String toString() => 'PagSeguroResult(success: $success, message: $message)';
}

/// Atalho para converter o retorno de qualquer método do plugin em [PagSeguroResult]
extension PagSeguroResultMap on Map<String, dynamic> {
  PagSeguroResult toPagSeguroResult() => PagSeguroResult.fromMap(this);
}
