package com.takeodev.pagseguro_smart.manager

/** ======================================================================================
Arquivo         : DeviceManager.kt
Projeto         : PagSeguro Smart
Plataforma      : Android
Equipamentos    : Modelos de Maquininhas PagSeguro testados - P2 A7, P2 A11 & GPOS A11
Autor           : Fernando Takeo Miyaji
====================================================================================== **/

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPag
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagActivationData
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagEventData
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagInitializationResult
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagInstallment
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagPrinterData
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagSubAcquirerData
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagSubAcquirerResult
import br.com.uol.pagseguro.plugpagservice.wrapper.data.request.PlugPagBeepData
import br.com.uol.pagseguro.plugpagservice.wrapper.data.request.PlugPagLedData
import br.com.uol.pagseguro.plugpagservice.wrapper.deeplink.enums.DeepLink
import br.com.uol.pagseguro.plugpagservice.wrapper.listeners.PlugPagActivationListener
import br.com.uol.pagseguro.plugpagservice.wrapper.listeners.PlugPagInstallmentsListener
import com.takeodev.pagseguro_smart.utils.Logger
import com.takeodev.pagseguro_smart.utils.ResultHelper
import com.takeodev.pagseguro_smart.utils.ResultHelper.fail
import com.takeodev.pagseguro_smart.utils.ResultHelper.ok

/**
 * Funcionalidades do Wrapper adicionadas na versão 1.4.0:
 * Dispositivo (modelo, capacidades, beep, LED), Parcelamento, Impressão de Arquivo,
 * Desativação/Ativação PagBank, Dados do Cartão, Subadquirente e Deeplink.
 */
class DeviceManager(private val plugPag: PlugPag, private val scope: CoroutineScope) {

    companion object {
        /** Tag utilizada nos logs */
        private const val TAG = "DeviceManager"
    }

    /** Logger personalizado com TAG para identificar a Origem **/
    private val logger = Logger(TAG)

    // ======================================================================================
    // DISPOSITIVO
    // ======================================================================================

    /** Modelo da Maquininha (ex.: "A930", "GPOS780") **/
    fun getModel(result: MethodChannel.Result) =
        ResultHelper.runIO(scope, result, logger, "getModel", "Erro ao Obter Modelo!") {
            ok("Coletado Modelo da Maquininha!", plugPag.getModel())
        }

    /** Verifica se a Maquininha possui uma capacidade de Hardware (constantes PlugPag) **/
    fun hasCapability(call: MethodCall, result: MethodChannel.Result) {
        val capability = call.argument<Int>("capability") ?: return result.success(fail("Capacidade Inválida!"))
        ResultHelper.runIO(scope, result, logger, "hasCapability", "Erro ao Verificar Capacidade!") {
            val has = plugPag.hasCapability(capability)
            ok(if (has) "Capacidade Disponível!" else "Capacidade Indisponível!", has)
        }
    }

    /** Verifica se a Maquininha possui uma capacidade de Software (com modo opcional) **/
    fun hasSoftwareCapability(call: MethodCall, result: MethodChannel.Result) {
        val capability = call.argument<Int>("capability") ?: return result.success(fail("Capacidade Inválida!"))
        val mode = call.argument<Int>("mode")
        ResultHelper.runIO(scope, result, logger, "hasSoftwareCapability", "Erro ao Verificar Capacidade!") {
            val has = if (mode == null) plugPag.hasSoftwareCapability(capability) else plugPag.hasSoftwareCapability(capability, mode)
            ok(if (has) "Capacidade Disponível!" else "Capacidade Indisponível!", has)
        }
    }

    /**
     * Verifica se o App tem permissão para usar o PlugPagService.
     * Tem timeout de 10s porque o PlugPagService pode não responder (a chamada fica travada);
     * nesse caso o Flutter recebe falha por tempo esgotado em vez de aguardar para sempre.
     */
    fun checkPermission(result: MethodChannel.Result) =
        ResultHelper.runIO(scope, result, logger, "checkPermission", "Erro ao Verificar Permissão!", timeoutMs = 10_000) {
            val allowed = plugPag.checkPermissionPlugPagService()
            if (allowed) ok("Permissão Concedida!", true) else fail("Permissão Negada!", false)
        }

    // Beep e LED rodam no "TerminalLib Service" (app do sistema), que pode estar fechado: abrir leva ~6s na GPOS780S.
    // Por isso o tempo limite é 20s (um limite menor cortava a chamada antes da resposta) e, se o serviço travar,
    // o Flutter recebe "tempo esgotado" em vez de ficar sem resposta.

    /** Emite um Beep (frequency: 0 a 6 | duration: milissegundos) **/
    fun beep(call: MethodCall, result: MethodChannel.Result) {
        val frequency = (call.argument<Int>("frequency") ?: 3).coerceIn(0, 6)
        val duration = (call.argument<Int>("duration") ?: 200).coerceAtLeast(1)
        ResultHelper.runIO(scope, result, logger, "beep", "Erro ao Emitir Beep!", timeoutMs = 20_000) {
            val ret = plugPag.beep(PlugPagBeepData(frequency.toByte(), duration))
            if (isTerminalOk(ret)) ok("Beep Emitido!", ret) else fail("Falha ao Emitir Beep ($ret)", ret)
        }
    }

    /** Acende LED da Maquininha (0: Desliga | 1: Vermelho | 2: Verde | 4: Amarelo | 8: Azul) **/
    fun setLed(call: MethodCall, result: MethodChannel.Result) {
        val led = call.argument<Int>("led") ?: 0
        ResultHelper.runIO(scope, result, logger, "setLed", "Erro ao Configurar LED!", timeoutMs = 20_000) {
            val ret = plugPag.setLed(PlugPagLedData(led.toByte()))
            if (isTerminalOk(ret)) ok("LED Configurado!", ret) else fail("Falha ao Configurar LED ($ret)", ret)
        }
    }

    /**
     * Beep e LED rodam no TerminalLib Service (não no PlugPagService), que retorna 1 em caso de sucesso
     * (log do BeepService no GPOS780S: "Operation finish without error" com retorno 1). Aceita também RET_OK (0).
     */
    private fun isTerminalOk(ret: Int) = ret == PlugPag.RET_OK || ret == 1

    /** Atualiza Configurações Remotas do PlugPagService **/
    fun updateRemoteConfig(result: MethodChannel.Result) =
        ResultHelper.runIO(scope, result, logger, "updateRemoteConfig", "Erro ao Atualizar Configurações!") {
            val ret = plugPag.updateRemoteConfig()
            if (ret == PlugPag.RET_OK) ok("Configurações Atualizadas!", ret) else fail("Falha ao Atualizar Configurações ($ret)", ret)
        }

    /** Abre o Fluxo de OnBoarding (primeiro acesso) do PlugPagService **/
    fun startOnBoarding(result: MethodChannel.Result) =
        ResultHelper.runIO(scope, result, logger, "startOnBoarding", "Erro ao Iniciar OnBoarding!") {
            plugPag.startOnBoarding()
            ok("OnBoarding Iniciado!")
        }

    /** Lê Dados do Cartão (BIN e Portador) sem realizar transação. Exige Cartão. **/
    fun getCardData(result: MethodChannel.Result) =
        ResultHelper.runIO(scope, result, logger, "getCardData", "Erro ao Ler Cartão!") {
            val card = plugPag.getCardData()
            val data = mapOf("result" to card.result, "message" to card.message, "bin" to card.bin, "holder" to card.holder, "cardHolder" to card.cardHolder)
            // O Wrapper retorna "result" como String ("0" = sucesso)
            if (card.result == PlugPag.RET_OK.toString()) ok("Dados do Cartão Lidos!", data) else fail(card.message ?: "Falha ao Ler Cartão!", data)
        }

    // ======================================================================================
    // ATIVAÇÃO / DESATIVAÇÃO
    // ======================================================================================

    /** Desativa o PinPad de forma Síncrona **/
    fun deactivate(call: MethodCall, result: MethodChannel.Result) {
        val code = call.argument<String>("activationCode").orEmpty()
        if (code.isEmpty()) return result.success(fail("Fornecer Código de Ativação"))
        ResultHelper.runIO(scope, result, logger, "deactivate", "Erro ao Desativar PinPad!") {
            initResponse(plugPag.deactivate(PlugPagActivationData(code)), "PinPad Desativado com Sucesso!")
        }
    }

    /** Desativa o PinPad de forma Assíncrona **/
    fun asyncDeactivate(call: MethodCall, result: MethodChannel.Result) {
        val code = call.argument<String>("activationCode").orEmpty()
        if (code.isEmpty()) return result.success(fail("Fornecer Código de Ativação"))
        try {
            plugPag.asyncDeactivate(PlugPagActivationData(code), object : PlugPagActivationListener {
                // Não chamar disposeSubscriber() no progresso: cancelaria a operação em andamento
                override fun onActivationProgress(eventData: PlugPagEventData) {
                    logger.info("asyncDeactivate (onActivationProgress)", "${eventData.eventCode} | ${eventData.customMessage}")
                }

                override fun onSuccess(initializationResult: PlugPagInitializationResult) =
                    ResultHelper.reply(scope, result, initResponse(initializationResult, "PinPad Desativado com Sucesso!"))

                override fun onError(initializationResult: PlugPagInitializationResult) =
                    ResultHelper.reply(scope, result, initResponse(initializationResult, "PinPad Desativado com Sucesso!"))
            })
        } catch (e: Exception) {
            logger.error("asyncDeactivate (Exception)", "Erro ao Desativar PinPad: ${e.message}")
            ResultHelper.reply(scope, result, fail("Erro ao Desativar PinPad!"))
        }
    }

    /** Invalida a Autenticação atual (exige nova ativação) **/
    fun invalidateAuthentication(result: MethodChannel.Result) =
        ResultHelper.runIO(scope, result, logger, "invalidateAuthentication", "Erro ao Invalidar Autenticação!") {
            plugPag.invalidateAuthentication()
            ok("Autenticação Invalidada!")
        }

    /** Inicia a Ativação via PagBank (fluxo próprio do PlugPagService) **/
    fun initPagBankActivation(result: MethodChannel.Result) =
        ResultHelper.runIO(scope, result, logger, "initPagBankActivation", "Erro na Ativação PagBank!") {
            val ret = plugPag.initPagBankActivation()
            val data = mapOf("result" to ret.result, "errorCode" to ret.errorCode, "errorMessage" to ret.errorMessage)
            if (ret.result == PlugPag.RET_OK) ok("Ativação PagBank Realizada!", data)
            else fail("${ret.errorMessage} (${ret.errorCode})", data)
        }

    /** Converte PlugPagInitializationResult na resposta padrão **/
    private fun initResponse(ret: PlugPagInitializationResult, successMessage: String): Map<String, Any?> =
        if (ret.result == PlugPag.RET_OK) ok(successMessage)
        else fail("${ret.errorMessage} (${ret.errorCode})")

    // ======================================================================================
    // PARCELAMENTO
    // ======================================================================================

    /**
     * Calcula Parcelas de forma Síncrona.
     * - Sem "installmentType": usa o método legado (Parcelado Comprador) e retorna lista de textos.
     * - Com "installmentType": retorna lista de mapas {quantity, amount, total} em centavos.
     * "amount" vem do Dart em Reais (double) e é convertido para centavos (String) como o Wrapper exige.
     */
    fun calculateInstallments(call: MethodCall, result: MethodChannel.Result) {
        val saleValue = amountInCents(call) ?: return result.success(fail("Valor Inválido para Parcelamento!"))
        val installmentType = call.argument<Int>("installmentType")
        ResultHelper.runIO(scope, result, logger, "calculateInstallments", "Erro ao Calcular Parcelas!") {
            val data: Any = if (installmentType == null) plugPag.calculateInstallments(saleValue).toList()
            else plugPag.calculateInstallments(saleValue, installmentType).map { it.toMap() }
            ok("Parcelas Calculadas!", data)
        }
    }

    /** Calcula Parcelas de forma Assíncrona (Parcelado Comprador) **/
    fun asyncCalculateInstallments(call: MethodCall, result: MethodChannel.Result) {
        val saleValue = amountInCents(call) ?: return result.success(fail("Valor Inválido para Parcelamento!"))
        try {
            plugPag.asyncCalculateInstallments(saleValue, object : PlugPagInstallmentsListener {
                override fun onCalculateInstallments(installments: Array<String>) {
                    logger.info("asyncCalculateInstallments (onCalculateInstallments)", "Parcelas: ${installments.size}")
                    ResultHelper.reply(scope, result, ok("Parcelas Calculadas!", installments.toList()))
                }

                override fun onCalculateInstallmentsWithTotalAmount(installments: Array<PlugPagInstallment>) =
                    ResultHelper.reply(scope, result, ok("Parcelas Calculadas!", installments.map { it.toMap() }))

                override fun onError(errorMessage: String) {
                    logger.error("asyncCalculateInstallments (onError)", errorMessage)
                    ResultHelper.reply(scope, result, fail(errorMessage))
                }
            })
        } catch (e: Exception) {
            logger.error("asyncCalculateInstallments (Exception)", "Erro ao Calcular Parcelas: ${e.message}")
            ResultHelper.reply(scope, result, fail("Erro ao Calcular Parcelas!"))
        }
    }

    /**
     * Converte "amount" (Reais) do Dart em centavos (String), retornando null se inválido.
     * Usa BigDecimal.valueOf (a partir do texto do Double) para evitar erro de ponto flutuante
     * (ex.: 0.29 * 100 = 28.999...) e arredonda meio para cima (HALF_UP) antes de converter.
     */
    private fun amountInCents(call: MethodCall): String? {
        val amount = call.argument<Double>("amount") ?: return null
        val cents = java.math.BigDecimal.valueOf(amount).multiply(java.math.BigDecimal(100))
            .setScale(0, java.math.RoundingMode.HALF_UP).toInt()
        return if (cents > 0) cents.toString() else null
    }

    // ======================================================================================
    // IMPRESSÃO
    // ======================================================================================

    /**
     * Imprime um Arquivo de Imagem (caminho absoluto no dispositivo, ex.: PNG/BMP).
     * printerQuality: 1 a 4 (padrão 4) | steps: avanço de papel após impressão.
     */
    fun printFromFile(call: MethodCall, result: MethodChannel.Result) {
        val filePath = call.argument<String>("filePath").orEmpty()
        if (filePath.isEmpty() || !java.io.File(filePath).exists()) return result.success(fail("Arquivo para Impressão não Encontrado!"))
        val quality = call.argument<Int>("printerQuality") ?: 4
        val steps = call.argument<Int>("steps") ?: 70
        ResultHelper.runIO(scope, result, logger, "printFromFile", "Erro ao Imprimir Arquivo!") {
            val ret = plugPag.printFromFile(PlugPagPrinterData(filePath, quality, steps))
            val data = mapOf("result" to ret.result, "steps" to ret.steps)
            if (ret.result == PlugPag.RET_OK) ok("Arquivo Impresso!", data) else fail("${ret.message} (${ret.errorCode})", data)
        }
    }

    // ======================================================================================
    // SUBADQUIRENTE (Facilitadores de Pagamento)
    // ======================================================================================

    /** Verifica se há Subadquirente configurado **/
    fun hasSubAcquirer(result: MethodChannel.Result) =
        ResultHelper.runIO(scope, result, logger, "hasSubAcquirer", "Erro ao Verificar Subadquirente!") {
            val has = plugPag.hasSubAcquirer()
            ok(if (has) "Subadquirente Configurado!" else "Sem Subadquirente!", has)
        }

    /** Retorna os Dados do Subadquirente configurado **/
    fun getSubAcquirerData(result: MethodChannel.Result) =
        ResultHelper.runIO(scope, result, logger, "getSubAcquirerData", "Erro ao Obter Subadquirente!") {
            // O Wrapper retorna null quando não há Subadquirente configurado
            val data = plugPag.getSubAcquirerData()
            if (data != null) ok("Dados do Subadquirente!", data.toMap()) else fail("Sem Subadquirente Configurado!")
        }

    /** Configura um Subadquirente (todos os campos são texto; limites de tamanho do Wrapper) **/
    fun initializeSubAcquirer(call: MethodCall, result: MethodChannel.Result) {
        fun arg(key: String) = call.argument<String>(key).orEmpty()
        val data = PlugPagSubAcquirerData(
            arg("name"), arg("address"), arg("city"), arg("uf"), arg("country"), arg("zipCode"),
            arg("mcc"), arg("cnpjCpf"), arg("docType"), arg("telephone"), arg("fullName"), arg("merchantId")
        )
        ResultHelper.runIO(scope, result, logger, "initializeSubAcquirer", "Erro ao Configurar Subadquirente!") {
            initResponse(plugPag.initializeSubAcquirer(data), "Subadquirente Configurado!")
        }
    }

    /** Remove o Subadquirente configurado **/
    fun invalidateSubAcquirer(result: MethodChannel.Result) =
        ResultHelper.runIO(scope, result, logger, "invalidateSubAcquirer", "Erro ao Remover Subadquirente!") {
            val removed = plugPag.invalidateSubAcquirer()
            if (removed) ok("Subadquirente Removido!", true) else fail("Falha ao Remover Subadquirente!", false)
        }

    // ======================================================================================
    // DEEPLINK
    // ======================================================================================

    /** Registra o Deeplink de Venda (o PlugPagService abre este link ao iniciar uma venda) **/
    fun setSellDeeplink(call: MethodCall, result: MethodChannel.Result) {
        val link = call.argument<String>("deeplink").orEmpty()
        if (link.isEmpty()) return result.success(fail("Deeplink Inválido!"))
        ResultHelper.runIO(scope, result, logger, "setSellDeeplink", "Erro ao Configurar Deeplink!") {
            plugPag.setDeeplink(DeepLink.SELL, link)
            ok("Deeplink Configurado!")
        }
    }

    /** Remove o Deeplink de Venda **/
    fun removeSellDeeplink(result: MethodChannel.Result) =
        ResultHelper.runIO(scope, result, logger, "removeSellDeeplink", "Erro ao Remover Deeplink!") {
            plugPag.removeDeeplink(DeepLink.SELL)
            ok("Deeplink Removido!")
        }
}

/** Extensão: PlugPagInstallment em Map (valores em centavos) **/
fun PlugPagInstallment.toMap(): Map<String, Any?> = mapOf("quantity" to quantity, "amount" to amount, "total" to total)

/** Extensão: PlugPagSubAcquirerResult em Map **/
fun PlugPagSubAcquirerResult.toMap(): Map<String, Any?> = mapOf(
    "name" to name, "address" to address, "city" to city, "uf" to uf, "country" to country, "zipCode" to zipCode,
    "mcc" to mcc, "cnpjCpf" to cnpjCpf, "docType" to docType, "telephone" to telephone, "fullName" to fullName, "merchantId" to merchantId
)
