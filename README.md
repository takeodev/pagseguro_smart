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
  - [Pagamentos](#4-3-pagamentos)
  - [Estorno](#4-4-estorno)
  - [Impressão & Recibos](#4-5-impressao-recibos)
  - [Callbacks](#4-6-callbacks)
- [Identificações PagSeguro](#5-identificacao)
  - [Tipos de Pagamento](#5-1-tipos-de-pagamento)
  - [Parcelamento](#5-2-parcelamento)
  - [Estorno](#5-3-estorno)
  - [Como Utilizar o "PagSeguroEnum"](#5-4-utilizar-enum)
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
  pagseguro_smart: ^1.3.3
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
final LayoutPreset preset = LayoutPreset.darkBlue;
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
  final transaction = TransactionModel.fromJsonToModel(result['data']);
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

---

## <span id="6-models"></span> 📄 Models

Inclui:

- `UserDataModel`
- `TransactionModel`

Todos com `fromJsonToModel()` para parse automático.

---

## <span id="7-notas-importantes"></span> 📝 Notas Importantes

- O plugin funciona **somente** em Android.
- A maquininha deve estar vinculada a um **usuário ativo** na PagSeguro e com o aplicativo configurado (salvo maquininha debug).
- Callbacks dependem do texto da maquininha — o comportamento pode variar por modelo.
- Recomenda-se testar em dispositivo físico real.

---

## <span id="8-desenvolvedor"></span> 👨‍💻 Desenvolvedor

<p align="center">
  <a href="https://www.takeodev.com/">
    <img src="https://www.takeodev.com/files/foto_takeo.png" width="120" height="120">
  </a>
  <br>
  <b>Fernando Takeo Miyaji</b>
</p>

---

## <span id="9-licenca"></span> ⚖️ Licença

MIT © 2025 **Fernando Takeo Miyaji**

---

## <span id="10-contribuicao"></span> ⭐ Contribuições

Pull Requests são sempre Bem Vindos!  
Se você gostou desse package, considere dar um *Like* no **pub.dev** ou no **[GitHub](https://github.com/takeodev)**.