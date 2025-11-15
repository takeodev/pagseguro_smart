/// Modelo de Dados do Usuário (PlugPagUserDataResult)
/// Documentação: https://pagseguro.github.io/pagseguro-sdk-plugpagservicewrapper/-wrapper-p-p-s/br.com.uol.pagseguro.plugpagservice.wrapper/-plug-pag-user-data-result/index.html
class UserDataModel {
  final String? userNickName;
  final String? email;
  final String? cnpjCpf;
  final String? companyName;
  final String? address;
  final String? city;
  final String? addressState;
  final String? addressComplement;

  const UserDataModel({
    this.userNickName,
    this.email,
    this.cnpjCpf,
    this.companyName,
    this.address,
    this.city,
    this.addressState,
    this.addressComplement,
  });

  /// Construtor vazio
  factory UserDataModel.empty() => const UserDataModel();

  /// Converte o modelo em JSON (Map)
  Map<String, dynamic> toJson() {
    final map = {
      'userNickName': userNickName?.trim(),
      'email': email?.trim(),
      'cnpjCpf': cnpjCpf?.trim(),
      'companyName': companyName?.trim(),
      'address': address?.trim(),
      'city': city?.trim(),
      'addressState': addressState?.trim(),
      'addressComplement': addressComplement?.trim(),
    }..removeWhere((_, value) => value == null || value == '');

    return map;
  }

  /// Cria um modelo a partir de um Map JSON
  factory UserDataModel.fromMap(dynamic json) {
    // Se json for null ou não for um Map, retorna modelo vazio
    if (json == null || json is! Map) return UserDataModel.empty();

    // Converte Map<Object?, Object?> para Map<String, dynamic>
    final map = Map<String, dynamic>.from(json);

    try {
      return UserDataModel(
        userNickName: map['userNickName'] as String?,
        email: map['email'] as String?,
        cnpjCpf: map['cnpjCpf'] as String?,
        companyName: map['companyName'] as String?,
        address: map['address'] as String?,
        city: map['city'] as String?,
        addressState: map['addressState'] as String?,
        addressComplement: map['addressComplement'] as String?,
      );
    } catch (_) {
      return UserDataModel.empty();
    }
  }

  /// Converte o modelo para String (útil em logs)
  @override
  String toString() => toJson().toString();
}
