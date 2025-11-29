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
  - [Pagamentos](#4-3-pagamentos)
  - [Estorno](#4-4-estorno)
  - [Reimpressão & Recibos](#4-5-reimpressao-recibos)
  - [Callbacks](#4-6-callbacks)
- [Constantes](#5-constantes)
  - [Tipos de Pagamento](#5-1-tipos-de-pagamento)
  - [Parcelamento](#5-2-parcelamento)
  - [Estorno](#5-3-estorno)
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
  pagseguro_smart: ^1.0.5+5
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

---

## <span id="4-3-pagamentos"></span> 💳 Pagamentos

```dart
final result = await pagSeguro.doPayment(
  type: PagSeguroType.credit,
  value: 50.00,
  userReference: 'pedido123',
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
final estorno = await pagSeguro.voidPayment(
  transactionCode: '123456',
  transactionId: '987654',
  voidType: PagSeguroVoid.common,
  printReceipt: true,
);
```

---

## <span id="4-5-reimpressao-recibos"></span> 🧾 Reimpressão & Recibos

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

## <span id="5-constantes"></span> 🔧 Constantes

### <span id="5-1-tipos-de-pagamento"></span> Tipos de Pagamento
- `PagSeguroType.credit`
- `PagSeguroType.debit`
- `PagSeguroType.pix`
- `PagSeguroType.voucher`

### <span id="5-2-parcelamento"></span> Parcelamento
- `PagSeguroInstallment.singlePay`
- `PagSeguroInstallment.forMerchant`
- `PagSeguroInstallment.forCustomer`

### <span id="5-3-estorno"></span> Estorno
- `PagSeguroVoid.common`
- `PagSeguroVoid.qrCode`

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