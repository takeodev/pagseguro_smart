# pagseguro_smart

[![pub package](https://img.shields.io/pub/v/pagseguro_smart?color=blue)](https://pub.dev/packages/pagseguro_smart)
[![likes](https://img.shields.io/pub/likes/pagseguro_smart)](https://pub.dev/packages/pagseguro_smart/score)
[![pub points](https://img.shields.io/pub/points/pagseguro_smart)](https://pub.dev/packages/pagseguro_smart/score)

<div align="center">
  <a href="https://www.takeodev.com/">
    <img src="https://www.takeodev.com/files/logo_takeo.png" alt="Desenvolvedor Takeo" height="80">
  </a>
</div>

---

**pagseguro_smart** é um plugin Flutter para integração completa com as maquininhas PagSeguro Smart (P2 A7, P2 A11 e GPOS A11).  
Permite pagamentos, estornos, callbacks de transação, reimpressão de recibos e comunicação direta com o *PlugPagServiceWrapper* no Android.

> ⚠️ **Plugin não oficial** — Compatível **somente com Android**.

---

## <span id="sumario"></span> 📘 Sumário

- [Sobre](#1-sobre)
- [Instalação](#2-instalacao)
- [Configuração Android](#3-configuracao)
  - [Permissões](#3-1-permissoes)
  - [Intent-Filter](#3-2-intent-filter)
  - [Ajustar minSdk / targetSdk](#3-3-sdk)
    - [Editar "android/local.properties"](#3-3-1-localproperties)
    - [Editar "android/app/build.gradle.kts" (Kotlin) ou "build.gradle" (Groovy)](#3-3-2-buildgradle)
      - [Se você usa Kotlin DSL (build.gradle.kts)](#3-3-2-1-kotlin-dsl)
      - [Se você usa Groovy DSL (build.gradle)](#3-3-2-2-groovy-dsl)
- [Como Utilizar](#4-uso)
  - [Importação](#4-1-importacao)
  - [Inicialização](#4-2-inicializacao)
    - [Verificando se PinPad está Autenticado](#4-2-1-verificando-pinpad)
    - [Ativando o PinPad](#4-2-2-ativando-pinpad)
    - [Layout de Janelas PagSeguro](#4-2-3-layout)
    - [Desativando, Invalidando e Ativação PagBank](#4-2-4-desativando-pinpad)
  - [Pagamentos](#4-3-pagamentos)
  - [Estorno](#4-4-estorno)
  - [Impressão & Recibos](#4-5-impressao-recibos)
    - [Imprimindo Imagem de Arquivo](#4-5-1-print-from-file)
  - [Callbacks](#4-6-callbacks)
  - [Dispositivo](#4-7-dispositivo)
  - [Parcelamento (Cálculo)](#4-8-parcelamento-calculo)
  - [Subadquirente](#4-9-subadquirente)
  - [Deeplink de Venda](#4-10-deeplink)
  - [App Example](#4-11-app-example)
- [Identificações PagSeguro](#5-identificacao)
  - [Tipos de Pagamento](#5-1-tipos-de-pagamento)
  - [Parcelamento](#5-2-parcelamento)
  - [Estorno](#5-3-estorno)
  - [Como Utilizar o "PagSeguroEnum"](#5-4-utilizar-enum)
  - [Cores de LED (PagSeguroLed)](#5-5-pagseguro-led)
- [Models](#6-models)
- [Notas Importantes](#7-notas-importantes)
- [Desenvolvedor](#8-desenvolvedor)
- [Licença](#9-licenca)
- [Contribuições](#10-contribuicao)
---

## <span id="1-sobre"></span> 🎯 Sobre

O objetivo do plugin é oferecer uma interface simples, segura e moderna para comunicação com o SDK **PagSeguro PlugPagServiceWrapper** diretamente de projetos Flutter.

Compatível apenas com máquinas POS Smart **P2 A7**, **P2 A11** e **GPOS A11**.

---

## <span id="2-instalacao"></span> 📦 Instalação

No `pubspec.yaml`:

```yaml
dependencies:
  pagseguro_smart: ^1.4.0
```

Execute:

```bash
flutter pub get
```

---

## <span id="3-configuracao"></span> ⚙️ Configuração Android

### <span id="3-1-permissoes"></span> 1️⃣ Permissão necessária

Adicione ao `AndroidManifest.xml`:

```xml
<uses-permission android:name="br.com.uol.pagseguro.permission.MANAGE_PAYMENTS"/>
```

### <span id="3-2-intent-filter"></span> 2️⃣ Intent-Filter
 
Dentro da `<activity>` principal:

```xml
<intent-filter>
    <action android:name="br.com.uol.pagseguro.PAYMENT"/>
    <category android:name="android.intent.category.DEFAULT"/>
</intent-filter>
```

---

### <span id="3-3-sdk"></span> 3️⃣ Ajustar minSdk / targetSdk

A PagSeguro exige **Assinatura V1 + V2**, que requer configurar o projeto para aceitar **minSdkVersion 23**:

---

### <span id="3-3-1-localproperties"></span> 📍 **1. Editar `android/local.properties`**

Adicione:

```
flutter.minSdkVersion=23
flutter.targetSdkVersion=28
```

> Você pode ajustar o targetSdkVersion depois, mas o default usado pelo plugin é **28** para máxima compatibilidade.

---

## <span id="3-3-2-buildgradle"></span> 📍 **2. Editar `android/app/build.gradle.kts` (Kotlin) ou `build.gradle` (Groovy)**

Para permitir que o app ajuste automaticamente o **minSdkVersion** e **targetSdkVersion** usando o arquivo `local.properties`, siga as instruções conforme o tipo do seu arquivo Gradle.

---

### <span id="3-3-2-1-kotlin-dsl"></span> 🟦 **Se você usa Kotlin DSL (`build.gradle.kts`)**

Adicione **no topo do arquivo**:

```kotlin
import java.util.Properties
import java.io.FileInputStream

val localProps = Properties()
val localPropsFile = rootProject.file("local.properties")
if (localPropsFile.exists()) {
    localProps.load(FileInputStream(localPropsFile))
}

val minSdkFromLocal = localProps.getProperty("flutter.minSdkVersion")?.toInt() ?: 23
val targetSdkFromLocal = localProps.getProperty("flutter.targetSdkVersion")?.toInt() ?: 34
```

Agora substitua (ou ajuste) a seção:

```kotlin
android {
    defaultConfig {
        minSdk = minSdkFromLocal
        targetSdk = targetSdkFromLocal
    }
}
```

---

### <span id="3-3-2-2-groovy-dsl"></span> 🟧 **Se você usa Groovy DSL (`build.gradle`)**

Adicione **no topo do arquivo**:

```groovy
import java.util.Properties
import java.io.FileInputStream

def localProps = new Properties()
def localPropsFile = rootProject.file("local.properties")

if (localPropsFile.exists()) {
    localProps.load(new FileInputStream(localPropsFile))
}

def minSdkFromLocal = (localProps.getProperty("flutter.minSdkVersion") ?: "23") as Integer
def targetSdkFromLocal = (localProps.getProperty("flutter.targetSdkVersion") ?: "34") as Integer
```

Agora substitua (ou ajuste) a seção:

```groovy
android {
    defaultConfig {
        minSdkVersion minSdkFromLocal
        targetSdkVersion targetSdkFromLocal
    }
}
```

---

Isso permite que seu app use automaticamente os valores do `local.properties`.

---

## <span id="4-uso"></span> 🚀 Como Utilizar

### <span id="4-1-importacao"></span> Importação

```dart
import 'package:pagseguro_smart/pagseguro_smart.dart';
```

---

## <span id="4-2-inicializacao"></span> 🔌 Inicialização

### <span id="4-2-1-verificando-pinpad"></span> Verificando se PinPad está Autenticado

```dart
final PagSeguroService pagSeguro = PagSeguroService();

Future<void> isAuthenticated() async {
  final result = await pagSeguro.isAuthenticated();

  if (result['success']) {
    print('PinPad Autenticado!');
  } else {
    print('${result['message']}');
  }
}
```

### <span id="4-2-2-ativando-pinpad"></span> Ativando o PinPad

```dart
Future<void> initPinPad(String codigoAtivacao) async {
  final result = await pagSeguro.initPinPad(codigoAtivacao);

  if (result['success']) {
    print('PinPad Ativado!');
  } else {
    print('${result['message']}');
  }
}
```

### <span id="4-2-3-layout"></span> Layout de Janelas PagSeguro

> ⚠️ **Nota sobre cores** — O SDK do PagSeguro PlugPag é sensível a cores inválidas.
Necessário atenção para evitar crashes como _**IllegalArgumentException: Unknown color**_.

```dart
final LayoutPreset layoutPreset = LayoutPreset.darkBlue;
final style = LayoutPresets.of(layoutPreset);

final result = await pagSeguro.setStyleData(
    headTextColor: style.headTextColor,
    headBackgroundColor: style.headBackgroundColor,
    contentTextColor: style.contentTextColor,
    contentTextValue1Color: style.contentTextValue1Color,
    contentTextValue2Color: style.contentTextValue2Color,
    positiveButtonTextColor: style.positiveButtonTextColor,
    positiveButtonBackground: style.positiveButtonBackground,
    negativeButtonTextColor: style.negativeButtonTextColor,
    negativeButtonBackground: style.negativeButtonBackground,
    genericButtonBackground: style.genericButtonBackground,
    genericButtonTextColor: style.genericButtonTextColor,
    genericSmsEditTextBackground: style.genericSmsEditTextBackground,
    genericSmsEditTextTextColor: style.genericSmsEditTextTextColor,
    lineColor: style.lineColor,
);
```

### <span id="4-2-4-desativando-pinpad"></span> Desativando, Invalidando e Ativação PagBank

- `deactivate(activationCode)` / `asyncDeactivate(activationCode)`: desativa o PinPad (use o mesmo código da ativação). A versão `async` responde pelo callback de resultado final.
- `invalidateAuthentication()`: invalida a autenticação atual; será necessário ativar o PinPad novamente.
- `initPagBankActivation()`: inicia a ativação pelo fluxo PagBank do PlugPagService.

```dart
Future<void> desativarPinPad(String codigoAtivacao) async {
  final result = await pagSeguro.deactivate(codigoAtivacao); // Ex.: '12345678' (código fictício)

  if (result['success']) {
    print('${result['message']}'); // "PinPad Desativado com Sucesso!"
  } else {
    print('Falha: ${result['message']}');
  }
}
```

Retorno: `{success, message, data}`. Em caso de sucesso, `message` descreve a operação. Em falha, `message` traz o motivo.

---

## <span id="4-3-pagamentos"></span> 💳 Pagamentos

```dart
PagSeguroEnum payType = PagSeguroEnum.tCredit;
final result = await pagSeguro.doPayment(
  type: payType,
  value: 50.00,
  userReference: 't${payType.code}p123', // Pode ser qualquer identificador com limite de 10 caracteres, nesse exemplo tem o Tipo (t), Código do Tipo (${payType.code}), Pedido (p), Número do Pedido (123)
  printReceipt: true,
);

if (result['success']) {
  final transaction = TransactionDataModel.fromMap(result['data']);
  print('Pagamento aprovado!');
} else {
  print('Falha: ${result['message']}');
}
```

---

## <span id="4-4-estorno"></span> ⛔ Estorno

```dart
PagSeguroEnum voidType = PagSeguroEnum.vCommon;
final estorno = await pagSeguro.voidPayment(
  transactionCode: '123456',
  transactionId: '987654',
  voidType: voidType,
  printReceipt: true,
);
```

> ℹ️ **Desde a 1.4.1**, a ação de recibo configurada em `setPrintActionListener` (perguntar, SMS, imprimir ou dispensar) também é entregue no estorno. Antes, o Wrapper PagSeguro 1.35.0 perdia essa ação no estorno e o resultado só chegava após ~120 s, com _**PP1064 - Tempo limite expirado**_. A correção é feita pelo plugin; nada muda no uso.

---

## <span id="4-5-impressao-recibos"></span> 🧾 Impressão & Recibos

Definir Ação de Impressão do Recibo do **Cliente**:

```dart
await pagSeguro.setPrintActionListener(
    askReceipt: true,
    smsReceipt: false,
    directReceipt: false,
);
```

Definir Estilo, Cor e Tempo de Exibição da Janela de Recibo do **Cliente**:

> ⚠️ **Nota sobre cores** — O SDK do PagSeguro PlugPag é sensível a cores inválidas.
Necessário atenção para evitar crashes como _**IllegalArgumentException: Unknown color**_.

```dart
await pagSeguro.setPlugPagCustomPrinterLayout('Comprovante');
```

Reimprimir via **Cliente**:

```dart
await pagSeguro.reprintCustomerReceipt();
```

Reimprimir via **Loja**:

```dart
await pagSeguro.reprintEstablishmentReceipt();
```

Enviar recibo via **SMS**:

```dart
await pagSeguro.sendReceiptSMS(
  transactionCode: '123456',
  phoneNumber: '11999999999',
);
```

### <span id="4-5-1-print-from-file"></span> Imprimindo Imagem de Arquivo

`printFromFile` imprime uma imagem (ex.: PNG) a partir de um **caminho absoluto** no dispositivo. Largura ideal da imagem: **384 px**.

```dart
final result = await pagSeguro.printFromFile(
  filePath: '/storage/emulated/0/Download/cupom.png', // Caminho absoluto (exemplo)
  printerQuality: 4, // De 1 a 4 (padrão 4)
  steps: 70, // Avanço de papel após a impressão (padrão 70)
);

if (result['success']) {
  print('${result['message']}'); // "Arquivo Impresso!"
} else {
  print('Falha: ${result['message']}');
}
```

Retorno: `{success, message, data}`, em que `data` contém `result` e `steps` do Wrapper. Se o arquivo não existir, retorna falha com a mensagem "Arquivo para Impressão não Encontrado!".

---

## <span id="4-6-callbacks"></span> 📡 Callbacks

O plugin envia mensagens de progresso durante o pagamento, recomendado colocar no **initState**:

```dart
@override
void initState() {
  super.initState();

  _pagSeguro.onPaymentProgress = (message, canAbort) {
    print('Status: $message');

    if (canAbort) {
      print('Permitido Cancelar Pagamento.');
    }
  };
}
```

**Eventos de pagamento (1.4.1):** o callback opcional `onPaymentEvent` é chamado logo depois de `onPaymentProgress`, com a assinatura `void Function(int eventCode, String message, bool canAbort)`. O `eventCode` é o código do Wrapper (`PlugPagEventData`), ou `-1` quando não informado.

```dart
pagSeguro.onPaymentEvent = (eventCode, message, canAbort) {
  if (eventCode == PagSeguroConstants.eventSaleApproved) {
    // transação autorizada: aguardar o resultado final
  }
};
```

Constantes principais em `PagSeguroConstants`:

- `eventWaitingCard = 0`: aguardando cartão.
- `eventSaleEnd = 4`: finalizado.
- `eventAuthorizing = 5`: autorizando.
- `eventDigitPassword = 16`: digitação de senha.
- `eventSaleApproved = 18`: transação autorizada.
- `eventSaleNotApproved = 19`: transação não aprovada.
- `eventDefault = -1`: código não informado.

> 💡 Prefira agir pelo **código** do evento (`eventCode`), e não pelo texto da mensagem, que pode variar por modelo de maquininha.

---

## <span id="4-7-dispositivo"></span> 🖲️ Dispositivo

Recursos de informação e de interação com a maquininha (versão 1.4.0).

### Modelo, Capacidades e Permissão

```dart
final modelo = await pagSeguro.getModel();
if (modelo['success']) print('Modelo: ${modelo['data']}'); // String, ex.: "GPOS780"

final temCapacidade = await pagSeguro.hasCapability(capacidade); // int: constante "PlugPag" do Wrapper
final temSoftware = await pagSeguro.hasSoftwareCapability(capacidade, mode: modo); // mode é opcional

final permissao = await pagSeguro.checkPermission();
```

- `getModel()`: retorno `data` é um texto com o modelo da maquininha.
- `hasCapability(int capability)` e `hasSoftwareCapability(int capability, {int? mode})`: retorno `data` é `bool`. Os valores de `capability` e `mode` são as constantes do Wrapper PagSeguro.
- `checkPermission()`: verifica se o App tem permissão para usar o PlugPagService. Retorno `data` é `bool`. Tem **tempo limite de 10s**, pois algumas maquininhas não respondem; nesse caso, a chamada retorna falha por tempo esgotado.

### Beep e LED

```dart
await pagSeguro.beep(frequency: 3, duration: 200); // frequency de 0 a 6; duration em milissegundos
await pagSeguro.setLed(PagSeguroLed.green); // ver "Cores de LED (PagSeguroLed)"
```

- `beep({frequency = 3, duration = 200})` e `setLed(PagSeguroLed led)`: têm **tempo limite de 20s**.
- Na GPOS780S, o TerminalLib retorna `1` em caso de sucesso, e o plugin trata esse valor como sucesso.

### Atualização Remota e OnBoarding

```dart
final atualizacao = await pagSeguro.updateRemoteConfig();
if (!atualizacao['success']) print('Falha: ${atualizacao['message']}');

await pagSeguro.startOnBoarding(); // Abre o fluxo de primeiro acesso do PlugPagService
```

- `updateRemoteConfig()`: atualiza as configurações remotas do PlugPagService. Em alguns equipamentos, retorna o código `-1033`, que aparece na `message` de falha.
  Trate essa falha e informe o usuário para tentar novamente.
- `startOnBoarding()`: abre o fluxo de OnBoarding (primeiro acesso).

### Leitura de Dados do Cartão

```dart
final cartao = await pagSeguro.getCardData(); // Exige um cartão apresentado na maquininha
if (cartao['success']) {
  final dados = cartao['data']; // {result, message, bin, holder, cardHolder}
}
```

> ⚠️ **LGPD** — `getCardData()` retorna dados do portador. Não registre esses dados em logs, telas ou servidores sem base legal e finalidade definidas.

### Retorno dos Métodos de Dispositivo

Todos retornam `{success, message, data}`. O campo `data` depende do método, conforme descrito acima.

---

## <span id="4-8-parcelamento-calculo"></span> 🧮 Parcelamento (Cálculo)

Calcula as parcelas de um valor (em Reais) sem iniciar uma venda.

### Sem tipo de parcelamento

```dart
final result = await pagSeguro.calculateInstallments(value: 100.00);

if (result['success']) {
  final List<String> parcelas = (result['data'] as List).cast<String>();
  // Posição 1 = 1x. Valores em centavos como texto.
  // Ex.: ["10000", "5848"] => 1x R$ 100,00 e 2x R$ 58,48
}
```

### Com tipo de parcelamento

```dart
final result = await pagSeguro.calculateInstallments(
  value: 100.00,
  installmentType: PagSeguroEnum.iForMerchant, // ou PagSeguroEnum.iForCustomer
);

if (result['success']) {
  final parcelas = InstallmentModel.fromList(result['data']);
  for (final p in parcelas) {
    print('${p.quantity}x de R\$ ${p.amountValue.toStringAsFixed(2)} (total R\$ ${p.totalValue.toStringAsFixed(2)})');
  }
}
```

- Sem `installmentType`: `data` é uma lista de **textos** com o valor de cada parcela em **centavos**, começando na posição 1 (1x).
- Com `installmentType`: `data` é uma lista de mapas `{quantity, amount, total}` em **centavos**, começando no 2x. Use `InstallmentModel.fromList()` para converter (ver [Models](#6-models)).

### Versão assíncrona

```dart
final result = await pagSeguro.asyncCalculateInstallments(value: 100.00);
```

- `asyncCalculateInstallments(value)` recebe apenas o valor. O resultado chega pelo callback do Wrapper e pode vir como lista de textos (centavos) ou de mapas `{quantity, amount, total}`, conforme o callback recebido.

Retorno: `{success, message, data}`. Em falha (valor inválido, por exemplo), `success` é `false`.

---

## <span id="4-9-subadquirente"></span> 🏦 Subadquirente

Configura um Subadquirente (facilitador de pagamento) na maquininha.

```dart
final temSub = await pagSeguro.hasSubAcquirer(); // data: bool

final result = await pagSeguro.initializeSubAcquirer(
  name: 'Loja Exemplo',
  address: 'Rua Exemplo, 100',
  city: 'Cidade Exemplo',
  uf: 'SP',
  country: 'BRA',
  zipCode: '00000000',
  mcc: '5411',
  cnpjCpf: '00000000000000', // Dados fictícios
  docType: 'CNPJ', // Confira os valores aceitos pelo Wrapper
  telephone: '11900000000',
  fullName: 'Responsavel Exemplo',
  merchantId: '000000',
);

final dados = await pagSeguro.getSubAcquirerData(); // data: Map com os dados do Subadquirente
await pagSeguro.invalidateSubAcquirer(); // Remove o Subadquirente configurado
```

- `hasSubAcquirer()`: retorno `data` é `bool`.
- `getSubAcquirerData()`: retorna falha "Sem Subadquirente Configurado!" quando não há Subadquirente.
- `initializeSubAcquirer(...)`: todos os campos são texto e devem respeitar os limites de tamanho do Wrapper.
- `invalidateSubAcquirer()`: remove o Subadquirente configurado.

> ⚠️ **LGPD** — os dados do Subadquirente incluem CPF/CNPJ, nome e telefone de pessoas físicas ou jurídicas. Use dados reais apenas no ambiente de produção, não os exiba em logs e não os envie a terceiros sem necessidade. Os exemplos acima são fictícios.

---

## <span id="4-10-deeplink"></span> 🔗 Deeplink de Venda

Registra um deeplink que o PlugPagService abre ao iniciar uma venda.

```dart
final result = await pagSeguro.setSellDeeplink('meuapp://venda'); // Link de exemplo
if (!result['success']) print('Falha: ${result['message']}');

await pagSeguro.removeSellDeeplink(); // Remove o deeplink de venda
```

- `setSellDeeplink(String deeplink)`: retorna `{success, message, data}`. Falha se o link estiver vazio.
- `removeSellDeeplink()`: retorna `{success, message, data}`.

---

## <span id="4-11-app-example"></span> 📱 App Example

O projeto `example/` demonstra o plugin em um app com três abas:

- **Pagamento**: pagamentos, estornos e demais operações de venda.
- **Comandos**: chamadas diretas aos métodos do plugin, com a opção **Modo Assíncrono** para testar os métodos assíncronos.
- **Recursos**: Dispositivo, Parcelamento, Impressão de Cupom, Leitura de Cartão e Subadquirente.

Para conhecer o app, toque no botão flutuante **Tour guiado** (canto inferior direito): o tour destaca cada bloco e botão das três abas e explica o que cada um faz.

Detalhes das versões do app: [example/CHANGELOG.md](example/CHANGELOG.md).

---

## <span id="5-identificacao"></span> 🔧 Identificações PagSeguro

O plugin possui facilitadores com identificações de **Tipos de Pagamento**, **Parcelamento** e **Estorno** da PagSeguro com códigos e descrição em **_enum_**:

### <span id="5-1-tipos-de-pagamento"></span> Tipos de Pagamento
- `PagSeguroEnum.tCredit`
- `PagSeguroEnum.tDebit`
- `PagSeguroEnum.tVoucher`
- `PagSeguroEnum.tPix`

### <span id="5-2-parcelamento"></span> Parcelamento
- `PagSeguroEnum.iSinglePay`
- `PagSeguroEnum.iForMerchant`
- `PagSeguroEnum.iForCustomer`

### <span id="5-3-estorno"></span> Estorno
- `PagSeguroEnum.vCommon`
- `PagSeguroEnum.vQrCode`

### <span id="5-4-utilizar-enum"></span> Como Utilizar o "**_PagSeguroEnum_**"

```dart
PagSeguroEnum pagSeguroEnum = PagSeguroEnum.tCredit;
print('Código: ${pagSeguroEnum.code}'); // Enviar para a PagSeguro sempre o Código
print('Descrição: ${pagSeguroEnum.description}'); // Utilizar para Tratativas Internas como preferir
```

### <span id="5-5-pagseguro-led"></span> Cores de LED (PagSeguroLed)

Usado em `setLed(PagSeguroLed led)`:

- `PagSeguroLed.off` (desliga)
- `PagSeguroLed.red`
- `PagSeguroLed.green`
- `PagSeguroLed.yellow`
- `PagSeguroLed.blue`

Use `led.code` para o valor enviado ao Wrapper (0, 1, 2, 4 ou 8).

---

## <span id="6-models"></span> 📄 Models

Inclui:

- `UserDataModel`
- `TransactionDataModel`
- `InstallmentModel` (parcela calculada com `installmentType`, ver [Parcelamento (Cálculo)](#4-8-parcelamento-calculo))

`UserDataModel` e `TransactionDataModel` são criados com `fromMap()` a partir do `data` retornado pelo plugin.

```dart
final parcelas = InstallmentModel.fromList(result['data']); // Lista de InstallmentModel
final valorParcela = parcelas.first.amountValue; // Em Reais (amount vem em centavos)
```

| Campo | Tipo | Descrição |
| --- | --- | --- |
| `quantity` | `int` | Quantidade de parcelas |
| `amount` | `int` | Valor de cada parcela, em centavos |
| `total` | `int` | Valor total, em centavos |
| `amountValue` | `double` | `amount` em Reais |
| `totalValue` | `double` | `total` em Reais |

---

## <span id="7-notas-importantes"></span> 📝 Notas Importantes

- O plugin funciona **somente** em Android.
- A maquininha deve estar vinculada a um **usuário ativo** na PagSeguro e com o aplicativo configurado (salvo maquininha debug).
- Callbacks dependem do texto da maquininha — o comportamento pode variar por modelo.
- Recomenda-se testar em dispositivo físico real.
- Alguns métodos da versão 1.4.0 têm **tempo limite**: `checkPermission` (10s), `beep` e `setLed` (20s). Em maquininhas que não respondem, a chamada retorna falha por tempo esgotado.
- **Tempo limite opcional (1.4.1):** `isAuthenticated`, `asyncIsAuthenticated`, `getUserData`, `getSerialNumber`, `isServiceBusy`, `getLastTransaction` e `asyncGetLastTransaction` aceitam `timeout: Duration`. Sem ele nada muda. Com ele, se o serviço PagBank travar (visto após muitas horas ligado; reiniciar a maquininha resolve), o retorno é `{success: false, message: PagSeguroService.timeoutMessage}` em vez de esperar para sempre. Exemplo: `final user = await pagSeguro.getUserData(timeout: const Duration(seconds: 15));`. Pagamento e estorno não têm timeout de propósito: cortar a espera poderia esconder uma transação aprovada.
- Dados pessoais (`getCardData`, `getSubAcquirerData`, `initializeSubAcquirer`) são sensíveis à LGPD: não registre em logs e use apenas o necessário.
- **Logs:** o plugin registra no Logcat o andamento das operações (nunca dados pessoais). Em produção, desligue com `await pagSeguro.setLogEnabled(false);` (erros continuam registrados).
- **Logs do Wrapper (LGPD):** o próprio Wrapper da PagSeguro registra no Logcat os dados da transação (ex.: BIN, final do cartão e `cardHash`). Isso não é controlado pelo plugin: não colete nem compartilhe o Logcat de maquininhas em produção.
- **Resultado tipado (opcional):** todos os métodos continuam devolvendo `Map`; para ler de forma tipada use `final r = (await pagSeguro.getModel()).toPagSeguroResult();` e então `r.success`, `r.message` e `r.data`.
- **`Constants` agora é `PagSeguroConstants`:** o nome antigo continua funcionando, mas está obsoleto e será removido na 2.0.

---

## <span id="8-desenvolvedor"></span> 👨‍💻 Desenvolvedor

<p align="center">
  <a href="https://www.takeodev.com/">
    <img src="https://www.takeodev.com/files/foto_takeo.png" width="120" height="120">
  </a>
  <br>
  <b>Fernando Takeo Miyaji</b>
</p>

Este pacote é **gratuito e de código aberto**, mantido por [Takeo](https://www.takeodev.com/) sem fins lucrativos. Se ele te ajudou:

- ⭐ Dê uma estrela no [GitHub](https://github.com/takeodev/pagseguro_smart) e um "like" no [pub.dev](https://pub.dev/packages/pagseguro_smart).
- 💬 Mantenha os créditos do desenvolvedor ao reutilizar ou divulgar o projeto.
- 🧪 Abra uma issue com dúvidas, sugestões ou erros encontrados.

> Projeto independente: não é um produto oficial da PagSeguro/PagBank.

---

## <span id="9-licenca"></span> ⚖️ Licença

MIT © 2025 **Fernando Takeo Miyaji**

---

## <span id="10-contribuicao"></span> ⭐ Contribuições

Pull Requests são sempre Bem Vindos!  
Se você gostou desse package, considere dar um *Like* no **pub.dev** ou no **[GitHub](https://github.com/takeodev)**.