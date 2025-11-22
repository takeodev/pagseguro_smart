# pagseguro_smart

[![pub package](https://img.shields.io/pub/v/pagseguro_smart?color=blue)](https://pub.dev/packages/pagseguro_smart)
[![likes](https://img.shields.io/pub/likes/pagseguro_smart)](https://pub.dev/packages/pagseguro_smart/score)
[![pub points](https://img.shields.io/pub/points/pagseguro_smart)](https://pub.dev/packages/pagseguro_smart/score)

<div align="center">
  <img src="assets/logo_pagseguro.png" alt="PagSeguro" height="80"/>
</div>

---

**pagseguro_smart** é um plugin Flutter para integração completa com as maquininhas PagSeguro Smart (P2 A7, P2 A11 e GPOS A11).  
Permite pagamentos, estornos, callbacks de transação, reimpressão de recibos e comunicação direta com o *PlugPagServiceWrapper* no Android.

> ⚠️ **Plugin não oficial** — Compatível **somente com Android**.

---

## 📘 Sumário

- [Sobre](#-sobre)
- [Instalação](#-instalação)
- [Configuração Android](#-configuração-android)
    - [Permissões](#1️⃣-permissão-necessária)
    - [Intent-Filter](#2️⃣-intent-filter)
    - [Ajustar minSdk / targetSdk](#3️⃣-ajustar-minsdk--targetsdk)
- [Uso](#-uso)
    - [Inicialização](#inicialização)
    - [Pagamentos](#pagamentos)
    - [Estorno](#estorno)
    - [Reimpressão & Recibos](#reimpressão--recibos)
    - [Callbacks](#callbacks)
- [Constantes](#-constantes)
- [Models](#-models)
- [Notas Importantes](#-notas-importantes)
- [Licença](#-licença)

---

## 🎯 Sobre

O objetivo do plugin é oferecer uma interface simples, segura e moderna para comunicação com o SDK **PagSeguro PlugPagServiceWrapper** diretamente de projetos Flutter.

Compatível apenas com máquinas POS Smart **P2 A7**, **P2 A11** e **GPOS A11**.

---

## 📦 Instalação

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

## ⚙️ Configuração Android

### 1️⃣ Permissão necessária

Adicione ao `AndroidManifest.xml`:

```xml
<uses-permission android:name="br.com.uol.pagseguro.permission.MANAGE_PAYMENTS"/>
```

### 2️⃣ Intent-Filter

Dentro da `<activity>` principal:

```xml
<intent-filter>
    <action android:name="br.com.uol.pagseguro.PAYMENT"/>
    <category android:name="android.intent.category.DEFAULT"/>
</intent-filter>
```

---

### 3️⃣ Ajustar minSdk / targetSdk

A PagSeguro exige **Assinatura V1 + V2**, que requer configurar o projeto para aceitar **minSdkVersion 23**:

---

### 📍 **1. Editar `android/local.properties`**

Adicione:

```
flutter.minSdkVersion=23
flutter.targetSdkVersion=28
```

> Você pode ajustar o targetSdkVersion depois, mas o default usado pelo plugin é **28** para máxima compatibilidade.

---

## 📍 **2. Editar `android/app/build.gradle.kts` (Kotlin) ou `build.gradle` (Groovy)**

Para permitir que o app ajuste automaticamente o **minSdkVersion** e **targetSdkVersion** usando o arquivo `local.properties`, siga as instruções conforme o tipo do seu arquivo Gradle.

---

### 🟦 **Se você usa Kotlin DSL (`build.gradle.kts`)**

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

### 🟧 **Se você usa Groovy DSL (`build.gradle`)**

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

## 🚀 Uso

### Importação

```dart
import 'package:pagseguro_smart/pagseguro_smart.dart';
```

---

## 🔌 Inicialização

### Verificando se PinPad está Autenticado

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

### Ativando o PinPad

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

## 💳 Pagamentos

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

## ⛔ Estorno

```dart
final estorno = await pagSeguro.voidPayment(
  transactionCode: '123456',
  transactionId: '987654',
  voidType: PagSeguroVoid.common,
  printReceipt: true,
);
```

---

## 🧾 Reimpressão & Recibos

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

## 📡 Callbacks

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

## 🔧 Constantes

### Tipos de Pagamento
- `PagSeguroType.credit`
- `PagSeguroType.debit`
- `PagSeguroType.pix`
- `PagSeguroType.voucher`

### Parcelamento
- `PagSeguroInstallment.singlePay`
- `PagSeguroInstallment.forMerchant`
- `PagSeguroInstallment.forCustomer`

### Estorno
- `PagSeguroVoid.common`
- `PagSeguroVoid.qrCode`

---

## 📄 Models

Inclui:

- `UserDataModel`
- `TransactionModel`

Todos com `fromJsonToModel()` para parse automático.

---

## 📝 Notas Importantes

- O plugin funciona **somente** em Android.
- A maquininha deve estar vinculada a um **usuário ativo** na PagSeguro e com o aplicativo configurado (salvo maquininha debug).
- Callbacks dependem do texto da maquininha — o comportamento pode variar por modelo.
- Recomenda-se testar em dispositivo físico real.


---

## ⚖️ Desenvolvedor

<p align="center">
  <a href="https://github.com/takeodev">
    <img src="https://avatars.githubusercontent.com/u/50700409?v=4" width="120" height="120">
  </a>
  <br>
  <b>Fernando Takeo Miyaji</b>
</p>

[https://github.com/takeodev](https://github.com/takeodev)

---

## ⚖️ Licença

MIT © 2025 **Fernando Takeo Miyaji**  