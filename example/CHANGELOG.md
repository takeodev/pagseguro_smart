# Changelog PagSeguro Smart Example (by Takeo)

## 1.1.1

- [Improve] Ícone do App: logo maior (borda transparente do "_app_icon_foreground.png_" recortada).
- [Improve] Ícone do App: margem adaptativa "~~_16%_~~" => "_2%_" ("_adaptive_icon_foreground_inset_").
- [Add] Nova aba "_Recursos_" com Dispositivo, Parcelamento, Impressão de Cupom, Leitura de Cartão e Subadquirente.
- [Add] Opção "_Modo Assíncrono_" na aba "Comandos" para testar os métodos assíncronos (autenticação até última transação).
- [Add] Tour guiado pelo App (botão flutuante "_Tour guiado_"): esmaece a tela, destaca cada bloco e botão das 3 abas e explica o que fazem.
- [Add] No Tour, passo-resumo por bloco com a lista de botões e opção "_Pular bloco_".
- [Add] Botão "_Imprimir Cupom_" (antes "Imprimir Imagem"): imprime um cupom eletrônico de mercado fictício com "**printFromFile**".
- [Improve] Janelas da aba "_Recursos_": explicam o recurso ("_O que é_"), mostram a "_Leitura_" das parcelas em R$ e seguem o
  padrão de janela inferior da aba "_Comandos_".
- [Add] Componente "_ScrollHintBox_": barra de rolagem visível e aviso "_Role para ver mais_" em janelas com conteúdo longo.
- [Improve] Explicação do "_Modo Assíncrono_": vantagens de cada modo e quando usar.
- [Add] Splash Screen animada com o logotipo do desenvolvedor (fade, zoom e brilho) no lugar da tela padrão do Flutter; toque para pular.
- [Add] Tela de abertura nativa (Android 12+) com fundo branco e o ícone do App, sem o logotipo do Flutter.
- [Upgrade] Ícone do App com o logotipo do desenvolvedor (ícone adaptativo gerado por "**flutter_launcher_icons**").
- [Add] Botão flutuante "_Sobre_" abre janela com créditos, links (site, pub.dev e GitHub) e pedido de apoio.
- [Fix] Botões "_Via SMS_" e "_Direto_" não funcionavam ("_Perguntar_" vencia no Android): agora enviam "_askReceipt: false_".
- [Fix] Botão "_Sem Recibo_" agora habilitado também com "_Direto_" ligado.
- [Fix] Estado dos botões de recibo só muda quando o plugin confirma o sucesso.
- [Improve] Campo "_Código_" de ativação começa vazio (removido o código padrão; cada desenvolvedor usa o seu, solicitado à PagSeguro).
- [Upgrade] Versão do Example "~~_1.0.15_~~" => "_1.1.1_".
- [Upgrade] Gradle "~~_8.12_~~" => "_9.9.2_".
- [Upgrade] Android Gradle Plugin "~~_8.9.1_~~" => "_9.5.2_".
- [Upgrade] Kotlin "~~_2.1.0_~~" => "_2.4.21_".
- [Upgrade] Migrado para "_Built-in Kotlin_" ("_android.builtInKotlin=true_"), removido "_kotlin-android_" e "_kotlinOptions_".

## 1.0.13

- [Improve] Formatação de Código Dart com Dimensão de Linha em 140 (afetou 8 arquivos).
- [Improve] Atualizado README.

## 1.0.12

- [Upgrade] Wrapper da PagSeguro "~~_1.30.52_~~" => "_1.33.0_".

## 1.0.11

- [Add] Opção de Impressão de Recibo do Cliente de forma direta, sem perguntar.

## 1.0.10

- [Add] Utilização de Layout "_pagSeguro_".
- [Add] "**PaymentProvider**": "_setFullStyleData_" une "_setStyleData_" e "_setPlugPagCustomPrinterLayout_".

## 1.0.9

- [Add] Segurança contra Método de Pagamento "_tMoney_".

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
