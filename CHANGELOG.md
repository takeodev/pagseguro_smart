# Changelog PagSeguro Smart (by Takeo)

## 1.4.1

- [Fix] "**voidPayment**" e "**asyncVoidPayment**": ação de recibo chega ao serviço; estorno em segundos (antes ~120 s, "_PP1064_").
- [Fix] "**voidPayment**" e "**asyncVoidPayment**": "**setPrintActionListener**" reaplicado antes do estorno (evita popup padrão de ~15 s).
- [Fix] "**voidPayment**": "_onPaymentProgress_" enviado ao Flutter mesmo sem venda anterior.
- [Add] Callback "**onPaymentEvent**" com "_eventCode_" numérico, mensagem e "_canAbort_".
- [Add] Códigos de evento em "**PagSeguroConstants**" ("_eventSaleApproved_" = 18, "_eventSaleEnd_" = 4, ...).
- [Add] Parâmetro opcional "_timeout_" nas consultas "**isAuthenticated**", "**getUserData**", "**getSerialNumber**", "**isServiceBusy**".
- [Add] Parâmetro opcional "_timeout_" em "**getLastTransaction**" e nas versões assíncronas ("_tempo esgotado_" se o serviço travar).
- [Add] Regras R8 para build release: "**consumer-rules.pro**" no plugin ("_-dontwarn_" do "_Parcelize_" e "_keep_" do Wrapper).
- [Improve] Log de diagnóstico no "**onPrint**" do recibo (sem dados pessoais).
- [Improve] Testes unitários de "**onPaymentEvent**" e do "_timeout_".

## 1.4.0

- [Add] Dispositivo: "**beep**", "**setLed**" (enum "_PagSeguroLed_"), "**updateRemoteConfig**", "**startOnBoarding**" e "**getCardData**".
- [Add] Dispositivo: "**getModel**", "**hasCapability**", "**hasSoftwareCapability**", "**checkPermission**" (com tempo limite de 10s).
- [Add] Ativação: "**deactivate**", "**asyncDeactivate**", "**invalidateAuthentication**" e "**initPagBankActivation**".
- [Add] Parcelamento: "**calculateInstallments**" e "**asyncCalculateInstallments**" com o modelo "_InstallmentModel_".
- [Add] Impressão: "**printFromFile**" (imprime imagem a partir de arquivo).
- [Add] Subadquirente: "**hasSubAcquirer**", "**getSubAcquirerData**", "**initializeSubAcquirer**" e "**invalidateSubAcquirer**".
- [Add] Deeplink de Venda: "**setSellDeeplink**" e "**removeSellDeeplink**".
- [Improve] "_ResultHelper_" (Android): chamadas novas respondem ao Flutter e logam só sucesso/mensagem (sem dados pessoais).
- [Fix] "**PagSeguroEnum**": "_tPreAuthCard_" (7 => 6), "_tQrCodeCredit_" (8 => 7), "_tPreAuthKeyed_" (9 => 8), como no Wrapper.
- [Fix] "**doAsyncPayment**", "**asyncVoidPayment**" e "**asyncInitPinPad**": removido "_disposeSubscriber_" do progresso
  (cancelava a operação antes do resultado final).
- [Fix] "**TransactionDataModel**": campos "_isDcc_", "_foreignAmount_", "_currencyDestinyLabel_", "_currencyOriginLabel_" e
  "_minorUnitsForeign_" agora enviados pelo Android.
- [Improve] Qualquer "_Exception_" (não só "_PlugPagException_") tratada em "**rebootDevice**", "**setStyleData**", "**asyncSetStyles**",
  "**sendReceiptSMS**" e "**setPlugPagCustomPrinterLayout**".
- [Improve] Corrotinas do plugin com "_SupervisorJob_" e tratador de exceção (falha em uma tarefa não cancela as demais).
- [Improve] "_abortRequested_" com "_@Volatile_" (acesso seguro entre threads).
- [Improve] Atualizado teste e adicionado teste dos códigos de tipos de pagamento.
- [Upgrade] Migrado para "_Built-in Kotlin_" (AGP 9+), sem aplicar o Kotlin Gradle Plugin (KGP) quando o App usa Built-in Kotlin.
- [Improve] "**android/build.gradle**": KGP aplicado automaticamente se o App não usa "_Built-in Kotlin_" ("_android.builtInKotlin=false_").
- [Improve] Em "**android/build.gradle**", "_kotlinOptions_" substituído por "_kotlin.compilerOptions_" (com fallback para KGP 1.x).
- [Remove] Classpath do Kotlin Gradle Plugin no "_buildscript_" do plugin (a versão do Kotlin agora é definida pelo App).
- [Improve] "**beep**" e "**setLed**" com tempo limite de 20s e retorno "_1_" do TerminalLib tratado como sucesso (testado na GPOS780S).
- [Fix] "**ResultHelper.runIO**": interrupção do Wrapper ("_lateinit property result..._") responde "_tempo esgotado_".
- [Fix] "**setPlugPagCustomPrinterLayout**" (Android): "_maxTimeShowPopup_" "~~_30_~~" => "_20_" (igual ao Dart; em segundos).
- [Improve] "**setPrintActionListener**": documentada a prioridade perguntar > SMS > direto (SMS/direto enviam "_askReceipt: false_").
- [Improve] Comentários explicativos em todo o código (Dart e Kotlin) e README atualizado para a 1.4.0.
- [Improve] Em "**invalidateSubAcquirer**", variável renomeada para não esconder a função "_ok()_".
- [Upgrade] "**android/build.gradle**": AGP do "_buildscript_" "~~_8.9.1_~~" => "_8.13.0_".
- [Improve] AGP mantido na série 8.x de propósito (uma 9.x exigiria Gradle 9 e poderia quebrar Apps com Gradle 8.14).
- [Fix] Versão mínima "~~_Flutter 3.0 / Dart 3.0_~~" => "_Flutter 3.27 / Dart 3.6_".
- [Improve] Motivo: "_Color.toARGB32()_" não existe antes disso (quem estava abaixo não compilava).
- [Improve] "**PaymentManager**" recebe o canal de progresso pelo construtor (antes estático, vazava entre engines Flutter).
- [Improve] Validações de venda e estorno centralizadas (sem duplicação entre síncrono e assíncrono), com o mesmo comportamento.
- [Fix] Em "**doPayment**" (síncrono), cancelamento pedido pelo App responde "_Pagamento Cancelado pelo Usuário!_", igual ao assíncrono.
- [Fix] Em "**asyncGetLastTransaction**", um erro não zera mais o indicador de cancelamento de um pagamento em andamento.
- [Remove] Variável estática sem uso "_plugPagChannel_" em "**ReceiptManager**".
- [Improve] "_topics_" e "_issue_tracker_" no "**pubspec.yaml**" para o pub.dev.
- [Add] "**setLogEnabled**": liga/desliga os logs informativos do plugin (padrão ligado; erros continuam registrados).
- [Add] "**PagSeguroResult**" e "_toPagSeguroResult()_": leitura tipada opcional do retorno (métodos seguem devolvendo "_Map_").
- [Improve] Classe "~~_Constants_~~" => "_PagSeguroConstants_" (nome antigo mantido como obsoleto até a 2.0, sem quebrar quem usa).
- [Improve] README: aviso de LGPD sobre os logs do próprio Wrapper da PagSeguro e como desligar os logs do plugin.
- [Improve] Testes de "**PagSeguroResult**", "**setLogEnabled**" e da compatibilidade de "_Constants_" (21 testes no total).

## 1.3.3

- [Upgrade] Wrapper da PagSeguro "~~_1.33.0_~~" => "_1.35.0_".

## 1.3.2

- [Improve] Atualizado README.

## 1.3.1

- [Upgrade] "_TransactionDataModel_" do Wrapper PagSeguro, novos campos: "pixTxIdCode", "isDcc", "foreignAmount", "currencyDestinyLabel".
- [Upgrade] "_TransactionDataModel_" do Wrapper PagSeguro, novos campos: "currencyOriginLabel", "minorUnitsForeign".

## 1.3.0

- [Improve] Formatação de Código Dart com Dimensão de Linha em 140 (afetou 20 arquivos).

## 1.2.9

- [Upgrade] Wrapper da PagSeguro "~~_1.30.52_~~" => "_1.33.0_".

## 1.2.8

- [Improve] Em "**setPrintActionListener**".
- [Add] Em "**reapplyPrintActionListener**" em "**doPayment**".
- [Improve] Atualizado README.

## 1.2.7

- [Improve] Em "**setPrintActionListener**".

## 1.2.6

- [Add] Log de Controle de Instância do "**plugPag**" do Wrapper da PagSeguro.

## 1.2.5

- [Add] Em "**setPrintActionListener**" adicionado parâmetro para Impressão Direta do Recibo de Cliente (sem perguntar).
- [Improve] Atualizado README.

## 1.2.4

- [Remove] Em "**LayoutPreset**", Layout "_blackPink_".
- [Add] Em "**LayoutPreset**" novo Layout "_pagSeguro_".
- [Improve] Em "**PagSeguroService**" e "_setStyleData_" ou "_setPlugPagCustomPrinterLayout_" todos os parâmetros opcionais.

## 1.2.3

- [Add] Em "**Constants**" adicionada utilitário "_cardPayments_".

## 1.2.2

- [Add] Em "**TransactionDataModel**" adicionada funcionalidade "_toJsonString()_".

## 1.2.1

- [Add] Método de Pagamento "_tMoney_" em "**Constants**" e "_PagSeguroEnum_" para Uso Interno.

## 1.2.0

- [Improve] Em "**Constants**", as classes de identificações de tipo de pagamento, parcelamento e estorno da PagSeguro se tornaram _enum_
  com código e descrição.
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
