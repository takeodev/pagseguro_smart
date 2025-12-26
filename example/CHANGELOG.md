# Changelog PagSeguro Smart Example (by Takeo)

## 1.0.8

- [Fix] As classes "_PagSeguroType_", "_PagSeguroInstallment_" e "_PagSeguroVoid_" se tornaram enum "_PagSeguroEnum_".
- [Improve] Forma de Utilizar os Layouts Pré-Configurados "**LayoutPreset**".

## 1.0.7

- [Fix] Função "_isServiceBusy_" do "**PaymentProvider**".
- [Add] Novas Cores em Estilo Visual de Janelas PagSeguro.

## 1.0.6

- [Improve] Verificador de Serviço da PagSeguro (Se Ocupado ou Livre).
- [Add] Configuração de Impressão de Recibo do Cliente.
- [Add] Estilo Visual (Cores) de Janelas PagSeguro.
- [Improve] Organizado Código do "**PaymentProvider**".
- [Improve] Autenticação do PinPad apenas ao Abrir o App.

## 1.0.5

- [Improve] Autenticação do PinPad ao Iniciar o App.

## 1.0.4

- [Fix] Versionamento no **pubspec.yaml**.
- [Fix] Versionamento no **CHANGELOG**.

## 1.0.3

- [Downgrade] app\build.gradle, minSdkVersion (24 => 23) - Pré-requisito PagSeguro para Assinatura V1.
- [Downgrade] app\build.gradle, targetSdkVersion (36 => 34) - Pré-requisito PagSeguro para Assinatura V1.
- [Add] Prefixos ao CHANGELOG.
- [Improve] Nome do App ao Instalar "PagSeguro Smart Example".
- [Removed] Funcionalidade "integration_test" pela dependência do minSdkVersion 24.

## 1.0.2

- [Add] Verificador de Autenticação do PinPad ao Iniciar o App.

## 1.0.1

- [Release] Primeiro Release do App Example.