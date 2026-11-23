package com.takeodev.pagseguro_smart.utils

/** ======================================================================================
Arquivo         : ResultHelper.kt
Projeto         : PagSeguro Smart
Plataforma      : Android
Equipamentos    : Modelos de Maquininhas PagSeguro testados - P2 A7, P2 A11 & GPOS A11
Autor           : Fernando Takeo Miyaji
====================================================================================== **/

import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.runInterruptible
import kotlinx.coroutines.withTimeoutOrNull

/**
 * Padroniza as respostas enviadas ao Flutter ({success, message, data}) e a execução
 * de chamadas bloqueantes do Wrapper PagSeguro.
 *
 * Usado pelos Managers (ex.: DeviceManager) para evitar repetição de código e garantir
 * que TODA chamada responda ao Flutter.
 */
object ResultHelper {

    private const val TIMEOUT_MESSAGE = "Sem Resposta do Serviço PagSeguro (tempo esgotado)!"

    /** Resposta de sucesso no padrão do plugin **/
    fun ok(message: String, data: Any? = null): Map<String, Any?> =
        mapOf("success" to true, "message" to message, "data" to data)

    /** Resposta de falha no padrão do plugin **/
    fun fail(message: String, data: Any? = null): Map<String, Any?> =
        mapOf("success" to false, "message" to message, "data" to data)

    /**
     * Executa [block] em thread de I/O (as chamadas síncronas do Wrapper são bloqueantes e
     * não podem rodar na Main Thread) e responde ao Flutter na Main Thread.
     *
     * Qualquer Exception é capturada e convertida em [fail] com [errorMessage], assim o
     * App nunca fecha e o Future do Dart nunca fica sem resposta.
     */
    fun runIO(
        scope: CoroutineScope,
        result: MethodChannel.Result,
        logger: Logger,
        tag: String,
        errorMessage: String,
        timeoutMs: Long? = null,
        block: () -> Map<String, Any?>
    ) {
        CoroutineHelper.launchIO(scope) {
            logger.info(tag, "Iniciado")
            val start = System.currentTimeMillis()
            val response = try {
                // Com timeoutMs: interrompe chamadas do Wrapper que podem travar sem resposta
                // (ex.: checkPermissionPlugPagService). Nunca usar em pagamentos/estornos.
                val value = if (timeoutMs == null) block()
                else withTimeoutOrNull(timeoutMs) { runInterruptible { block() } }
                    ?: fail(TIMEOUT_MESSAGE)
                // Loga apenas success/message (nunca "data": pode conter dados pessoais - LGPD)
                value.also { logger.info(tag, "success: ${it["success"]} | ${it["message"]}") }
            } catch (e: Exception) {
                logger.error("$tag (Exception)", "$errorMessage: ${e.message}")
                // Ao ser interrompido pelo timeout, o Wrapper lança uma Exception própria
                // ("lateinit property result...") em vez de retornar: tratar como tempo esgotado
                if (timeoutMs != null && System.currentTimeMillis() - start >= timeoutMs) fail(TIMEOUT_MESSAGE)
                else fail(errorMessage)
            }
            CoroutineHelper.launchMain(scope) { result.success(response) }
        }
    }

    /** Responde ao Flutter na Main Thread (usado nos listeners assíncronos do Wrapper) **/
    fun reply(scope: CoroutineScope, result: MethodChannel.Result, response: Map<String, Any?>) {
        CoroutineHelper.launchMain(scope) { result.success(response) }
    }
}
