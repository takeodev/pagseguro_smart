# Changelog PagSeguro Smart (by Takeo)

## 1.2.0

- [Improve] Em "**Constants**", as classes de identificações de tipo de pagamento, parcelamento e estorno da PagSeguro se tornaram _enum_ com código e descrição.
- [Remove] Em "**Constants**", classes "_~~PagSeguroType~~_", "_~~PagSeguroInstallment~~_" e "_~~PagSeguroVoid~~_".
- [Add] Em "**Constants**", enum "_PagSeguroEnum_" para substituir as classes removidas.
- [Add] Model de "_PlugPagStyleData_" da PagSeguro e nomeado como "**StyleDataModel**".
- [Improve] Forma de Utilizar os Layouts Pré-Configurados "**LayoutPreset**".
- [Improve] Atualizado README.

## 1.1.2

- [Add] Segurança com HEX Completo em "**LayoutPresets**".
- [Add] Layouts Pré-Configurados "**LayoutPreset.warmSunset** & **LayoutPreset.warmLight**".
- [Improve] Atualizado README.

## 1.1.1

- [Improve] Verificador de Serviço da PagSeguro (Ocupado ou Livre).
- [Add] Dispose de Métodos Assíncronos (_plugPag.disposeSubscriber_).
- [Add] Método Síncrono "_setPrintActionListener_".
- [Add] Método Síncrono "_setStyleData_".
- [Add] Método Assíncrono "_asyncSetStyles_".
- [Add] Método Síncrono "_setPlugPagCustomPrinterLayout_".
- [Add] Layouts Pré-Configurados de Janelas PagSeguro "**LayoutPresets**".
- [Improve] Segurança de Valores de _Double_ > _Integer_ (Aceito pelo Wrapper da PagSeguro).

## 1.1.0

- [Fix] Packaged name "_~~takeodev.pagseguro_smart~~_" => "_com.takeodev.pagseguro_smart_".
- [Improve] Renomeado Métodos Assíncronos e Adicionados Métodos Síncronos.
- [Change] Método Assíncrono "_~~isAuthenticated~~_" => "_asyncIsAuthenticated_".
- [Change] Método Assíncrono "_~~initPinPad~~_" => "_asyncInitPinPad_".
- [Change] Método Assíncrono "_~~doPayment~~_" => "_doAsyncPayment_".
- [Change] Método Assíncrono "_~~abortTransaction~~_" => "_asyncAbortTransaction_".
- [Change] Método Assíncrono "_~~voidPayment~~_" => "_asyncVoidPayment_".
- [Change] Método Assíncrono "_~~getLastTransaction~~_" => "_asyncGetLastTransaction_".
- [Change] Método Assíncrono "_~~reprintCustomerReceipt~~_" => "_asyncReprintCustomerReceipt_".
- [Change] Método Assíncrono "_~~reprintEstablishmentReceipt~~_" => "_asyncReprintEstablishmentReceipt_".
- [Add] Método Síncrono "_isAuthenticated_".
- [Add] Método Síncrono "_initPinPad_".
- [Add] Método Síncrono "_doPayment_".
- [Add] Método Síncrono "_abortTransaction_".
- [Add] Método Síncrono "_voidPayment_".
- [Add] Método Síncrono "_getLastTransaction_".
- [Add] Método Síncrono "_reprintCustomerReceipt_".
- [Add] Método Síncrono "_reprintEstablishmentReceipt_".
- [Add] Adicionados Novos Métodos no Plugin (_src/pagseguro_service.dart_).

## 1.0.8

- [Fix] Versionamento no **pubspec.yaml**.
- [Fix] Versionamento no **CHANGELOG**.
- [Improve] Atualizado README.

## 1.0.7

- [Improve] Atualizado Hiperlinks de Segundo e Terceiro Nível de Sumário.

## 1.0.6

- [Improve] Atualizado Hiperlinks de Sumário e Logotipo PagSeguro no README.

## 1.0.5

- [Downgrade] app\build.gradle, minSdk (~~24~~ => 23) - Pré-requisito PagSeguro para Assinatura V1.
- [Improve] Atualizado README.

## 1.0.4

- [Add] Adicionado Verificador de Autenticação do PinPad.
- [Improve] Atualizado App de Exemplo para Verificar Ativação do PinPad ao Abrir.
- [Improve] Atualizado README.
- [Add] Adicionado Prefixos ao CHANGELOG.

## 1.0.3

- [Improve] Adicionado Desenvolvedor ao README.

## 1.0.2

- [Improve] Adicionado Badges ao README.

## 1.0.1

- [Release] Primeiro Release do Plugin.