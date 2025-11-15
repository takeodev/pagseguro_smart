package takeodev.pagseguro_smart.manager

/** ======================================================================================
Arquivo         : ReceiptManager.kt
Projeto         : PagSeguro Smart
Plataforma      : Android
Equipamentos    : Modelos de Maquininhas PagSeguro testados - P2 A7, P2 A11 & GPOS A11
Autor           : Fernando Takeo Miyaji
====================================================================================== **/

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPag
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagPrintResult
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagPrinterListener
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagReceiptSMSData
import br.com.uol.pagseguro.plugpagservice.wrapper.exception.PlugPagException
import takeodev.pagseguro_smart.utils.Logger
import takeodev.pagseguro_smart.utils.CoroutineHelper

/** Gerencia todas as operações de impressão **/
class ReceiptManager(private val plugPag: PlugPag, private val scope: CoroutineScope) {

    companion object {
        /** Tag utilizada nos logs */
        private const val TAG = "ReceiptManager"

        /** Canal global para envio de progresso ao Flutter */
        var plugPagChannel: MethodChannel? = null
    }

    private val logger = Logger(TAG)

    /** Reimpressão de Recibo: Via do Cliente **/
    fun reprintCustomerReceipt(result: MethodChannel.Result) {
        try {
            plugPag.asyncReprintCustomerReceipt(object : PlugPagPrinterListener {
                override fun onSuccess(printResult: PlugPagPrintResult) {
                    CoroutineHelper.launchMain(scope) {
                        logger.info("reprintCustomerReceipt (onSuccess)", "Reimpresso Recibo do Cliente")
                        val map = mapOf(
                            "result" to printResult.result,
                            "steps" to printResult.steps
                        )
                        result.success(mapOf(
                            "success" to true,
                            "message" to "Reimpresso Recibo do Cliente!",
                            "data" to map
                        ))
                    }
                }

                override fun onError(printResult: PlugPagPrintResult) {
                    CoroutineHelper.launchMain(scope) {
                        logger.error("reprintCustomerReceipt (onError)", "Erro na Reimpressão de Recibo do Cliente | Id: ${printResult.errorCode}")
                        result.success(mapOf(
                            "success" to false,
                            "message" to "${printResult.message} (${printResult.errorCode})",
                            "data" to null
                        ))
                    }
                }
            })
        } catch (e: Exception) {
            CoroutineHelper.launchMain(scope) {
                logger.error("reprintCustomerReceipt (Exception)", "Erro na Reimpressão de Recibo do Cliente: ${e.message}")
                result.success(mapOf(
                    "success" to false,
                    "message" to "Erro Fatal na Reimpressão de Recibo do Cliente!",
                    "data" to null
                ))
            }
        }
    }

    /** Reimpressão de Recibo: Via da Loja **/
    fun reprintEstablishmentReceipt(result: MethodChannel.Result) {
        try {
            plugPag.asyncReprintEstablishmentReceipt(object : PlugPagPrinterListener {
                override fun onSuccess(printResult: PlugPagPrintResult) {
                    CoroutineHelper.launchMain(scope) {
                        logger.info("reprintEstablishmentReceipt (onSuccess)", "Reimpresso Recibo da Loja")
                        val map = mapOf(
                            "result" to printResult.result,
                            "steps" to printResult.steps
                        )
                        result.success(mapOf(
                            "success" to true,
                            "message" to "Reimpresso Recibo da Loja!",
                            "data" to map
                        ))
                    }
                }

                override fun onError(printResult: PlugPagPrintResult) {
                    CoroutineHelper.launchMain(scope) {
                        logger.error("reprintEstablishmentReceipt (onError)", "Erro na Reimpressão de Recibo da Loja | Id: ${printResult.errorCode}")
                        result.success(mapOf(
                            "success" to false,
                            "message" to "${printResult.message} (${printResult.errorCode})",
                            "data" to null
                        ))
                    }
                }
            })
        } catch (e: Exception) {
            CoroutineHelper.launchMain(scope) {
                logger.error("reprintEstablishmentReceipt (Exception)", "Erro na Reimpressão de Recibo da Loja: ${e.message}")
                result.success(mapOf(
                    "success" to false,
                    "message" to "Erro Fatal na Reimpressão de Recibo da Loja!",
                    "data" to null
                ))
            }
        }
    }

    /** Envia Recibo via SMS **/
    fun sendReceiptSMS(call: MethodCall, result: MethodChannel.Result) {
        try {
            val phoneNumber = call.argument<String>("phoneNumber") ?: ""
            val transactionCode = call.argument<String>("transactionCode") ?: ""

            // Validação de Código
            if (transactionCode.isEmpty())  {
                logger.warn("transactionCode.isEmpty()", "Código da Transação Vazio!")
                result.success(mapOf(
                    "success" to false,
                    "message" to "Identificação de Transação Inválida!",
                    "data" to null
                ))
                return
            }

            // Validação de ID
            if (phoneNumber.isEmpty()) {
                logger.warn("phoneNumber.isEmpty()", "Número do Celular Vazio!")
                result.success(mapOf(
                    "success" to false,
                    "message" to "Número do Celular Inválido!",
                    "data" to null
                ))
                return
            }

            val smsData = PlugPagReceiptSMSData(
                phoneNumber = phoneNumber,
                transactionCode = transactionCode
            )

            CoroutineHelper.launchIO(scope) { // roda em thread de background
                val smsReturn = plugPag.sendReceiptSMS(smsData = smsData)

                CoroutineHelper.launchMain(scope) {
                    if (smsReturn == true) {
                        logger.info("sendReceiptSMS (smsReturn == true)", "Sucesso ao Enviar Recibo via SMS")
                        result.success(
                            mapOf(
                                "success" to true,
                                "message" to "Enviado Recibo via SMS!",
                                "data" to null
                            )
                        )
                    } else {
                        logger.error("sendReceiptSMS (smsReturn == null || smsReturn == false)", "Falha ao Enviar Recibo via SMS")
                        result.success(
                            mapOf(
                                "success" to false,
                                "message" to "Falha ao Enviar Recibo via SMS.",
                                "data" to null
                            )
                        )
                    }
                }
            }
        } catch (e: PlugPagException) {
            CoroutineHelper.launchMain(scope) {
                logger.error("sendReceiptSMS (PlugPagException)", "Erro ao Enviar SMS: ${e.message}")
                result.success(mapOf(
                    "success" to false,
                    "message" to "Erro Fatal ao Enviar SMS!",
                    "data" to null
                ))
            }
        }
    }
}