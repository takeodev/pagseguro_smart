package takeodev.pagseguro_smart.manager

/** ======================================================================================
Arquivo         : PaymentManager.kt
Projeto         : PagSeguro Smart
Plataforma      : Android
Equipamentos    : Modelos de Maquininhas PagSeguro testados - P2 A7, P2 A11 & GPOS A11
Autor           : Fernando Takeo Miyaji
====================================================================================== **/

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPag
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagPaymentData
import br.com.uol.pagseguro.plugpagservice.wrapper.listeners.PlugPagPaymentListener
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagEventData
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagTransactionResult
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagPrintResult
import br.com.uol.pagseguro.plugpagservice.wrapper.listeners.PlugPagAbortListener
import br.com.uol.pagseguro.plugpagservice.wrapper.listeners.PlugPagLastTransactionListener
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagVoidData
import takeodev.pagseguro_smart.utils.Logger
import takeodev.pagseguro_smart.utils.CoroutineHelper

/** Gerencia todas as operações de pagamento **/
class PaymentManager(private val plugPag: PlugPag, private val scope: CoroutineScope) {

    companion object {
        /** Tag utilizada nos logs */
        private const val TAG = "PaymentManager"

        /** Canal global para envio de progresso ao Flutter */
        var plugPagChannel: MethodChannel? = null
    }

    private val logger = Logger(TAG)

    /** Variável para indicar se o cancelamento foi solicitado **/
    private var abortRequested = false

    /** Executa um pagamento **/
    fun doPayment(call: MethodCall, result: MethodChannel.Result) {
        try {
            abortRequested = false

            val amount = call.argument<Double>("amount") ?: 0.0
            val amountInCents = (amount * 100).toInt()

            val type = call.argument<Int>("type") ?: PlugPag.TYPE_CREDITO
            var installmentType = call.argument<Int>("installmentType") ?: PlugPag.INSTALLMENT_TYPE_A_VISTA
            var installments = call.argument<Int>("installments") ?: PlugPag.A_VISTA_INSTALLMENT_QUANTITY
            val userReference = (call.argument<String>("userReference") ?: "").replace(Regex("[^A-Za-z0-9]"), "")
            val printReceipt = call.argument<Boolean>("printReceipt") ?: false

            // Validações
            if (amountInCents < 100) {
                logger.warn("amountInCents < 100", "Valor Inválido para Pagamento!")
                result.success(mapOf(
                    "success" to false,
                    "message" to "Valor Inválido para Pagamento!",
                    "data" to null
                ))
                return
            }

            if (userReference.isEmpty() || userReference.length > 10) {
                logger.warn("userReference.isEmpty() || userReference.length > 10", "Identificação do Cliente Inválida!")
                result.success(mapOf(
                    "success" to false,
                    "message" to "Identificação do Cliente Inválida!",
                    "data" to null
                ))
                return
            }

            // Ajusta parcelas
            if (installmentType == PlugPag.INSTALLMENT_TYPE_A_VISTA && installments != PlugPag.A_VISTA_INSTALLMENT_QUANTITY)
                installments = PlugPag.A_VISTA_INSTALLMENT_QUANTITY
            if (installmentType != PlugPag.INSTALLMENT_TYPE_A_VISTA && installments == PlugPag.A_VISTA_INSTALLMENT_QUANTITY)
                installmentType = PlugPag.INSTALLMENT_TYPE_A_VISTA
            if (installmentType != PlugPag.INSTALLMENT_TYPE_A_VISTA && installments < 2) {
                result.success(mapOf(
                    "success" to false,
                    "message" to "Número de Parcelas Inválido!",
                    "data" to null
                ))
                return
            }

            val paymentData = PlugPagPaymentData(
                type = type,
                amount = amountInCents,
                installmentType = installmentType,
                installments = installments,
                userReference = userReference,
                printReceipt = printReceipt,
                partialPay = false,
                isCarne = false
            )

            plugPag.doAsyncPayment(paymentData, object : PlugPagPaymentListener {

                override fun onPaymentProgress(eventData: PlugPagEventData) {
                    CoroutineHelper.launchMain(scope) {
                        logger.info("doPayment (onPaymentProgress)", "Realizando Pagamento | Id: ${eventData.eventCode} | ${eventData.customMessage}")
                        plugPagChannel?.invokeMethod("onPaymentProgress", mapOf(
                            "eventCode" to eventData.eventCode,
                            "message" to eventData.customMessage,
                            "data" to null
                        ))
                    }
                }

                override fun onSuccess(transactionResult: PlugPagTransactionResult) {
                    CoroutineHelper.launchMain(scope) {
                        val map = transactionResult.toMap()
                        logger.info("doPayment (onSuccess)", "Pagamento Realizado | Id: ${transactionResult.transactionId}")
                        result.success(mapOf(
                            "success" to true,
                            "message" to "Pagamento Realizado com Sucesso!",
                            "data" to map
                        ))
                    }
                }

                    override fun onError(transactionResult: PlugPagTransactionResult) {
                    CoroutineHelper.launchMain(scope) {
                        val map = transactionResult.toMap()
                        if (abortRequested) {
                            logger.info("doPayment (onError)", "Pagamento Cancelado pelo Usuário | Id: ${transactionResult.errorCode} | Message: ${transactionResult.message}")
                            result.success(mapOf(
                                "success" to false,
                                "message" to "Pagamento Cancelado pelo Usuário!",
                                "data" to map
                            ))
                        } else {
                            logger.error("doPayment (onError)", "Erro no Pagamento | Id: ${transactionResult.errorCode} | Message: ${transactionResult.message}")
                            result.success(mapOf(
                                "success" to false,
                                "message" to "${transactionResult.message} (${transactionResult.errorCode})",
                                "data" to map
                            ))
                        }
                    }
                }

                override fun onPrinterSuccess(printerResult: PlugPagPrintResult) {
                    CoroutineHelper.launchMain(scope) {
                        logger.info("doPayment (onPrinterSuccess)", "Impressão de Recibo com Sucesso | Id: ${printerResult.errorCode}")
                    }
                }

                override fun onPrinterError(printerResult: PlugPagPrintResult) {
                    CoroutineHelper.launchMain(scope) {
                        logger.warn("doPayment (onPrinterError)", "Erro na Impressão do Recibo | Id: ${printerResult.errorCode}")
                    }
                }
            })
        } catch (e: Exception) {
            CoroutineHelper.launchMain(scope) {
                logger.error("doPayment (Exception)", "Erro ao Realizar Pagamento: ${e.message}")
                result.success(mapOf(
                    "success" to false,
                    "message" to "Erro Fatal ao Realizar Pagamento!",
                    "data" to null
                ))
            }
        }
    }

    /** Solicita o cancelamento de transação **/
    fun abortTransaction(result: MethodChannel.Result) {
        try {
            abortRequested = true
            plugPag.asyncAbort(object : PlugPagAbortListener {
                override fun onAbortRequested(abortResult: Boolean) {
                    CoroutineHelper.launchMain(scope) {
                        abortRequested = abortResult
                        if (abortResult) {
                            logger.info("abortTransaction (onAbortRequested)", "Solicitado Cancelamento")
                            result.success(mapOf(
                                "success" to true,
                                "message" to "Solicitado Cancelamento",
                                "data" to null
                            ))
                        } else {
                            logger.warn("abortTransaction (onAbortRequested)", "Falha ao Solicitar Cancelamento")
                            result.success(mapOf(
                                "success" to false,
                                "message" to "Falha ao Solicitar Cancelamento",
                                "data" to null
                            ))
                        }
                    }
                }

                override fun onError(errorMessage: String) {
                    abortRequested = false
                    CoroutineHelper.launchMain(scope) {
                        logger.error("abortTransaction (onError)", "Erro ao Cancelar Transação: $errorMessage")
                        result.success(mapOf(
                            "success" to false,
                            "message" to "$errorMessage",
                            "data" to null
                        ))
                    }
                }
            })
        } catch (e: Exception) {
            abortRequested = false
            CoroutineHelper.launchMain(scope) {
                logger.error("abortTransaction (Exception)", "Erro ao Solicitar Cancelamento: ${e.message}")
                result.success(mapOf(
                    "success" to false,
                    "message" to "Erro Fatal ao Solicitar Cancelamento!",
                    "data" to null
                ))
            }
        }
    }

    /** Estorna Pagamento **/
    fun voidPayment(call: MethodCall, result: MethodChannel.Result) {
        try {
            abortRequested = false

            val transactionCode = call.argument<String>("transactionCode") ?: ""
            val transactionId = call.argument<String>("transactionId") ?: ""
            val printReceipt = call.argument<Boolean>("printReceipt") ?: false
            val voidType = call.argument<Int>("voidType") ?: PlugPag.VOID_PAYMENT // PlugPag.VOID_QRCODE

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
            if (transactionId.isEmpty()) {
                logger.warn("transactionId.isEmpty()", "ID da Transação Vazio!")
                result.success(mapOf(
                    "success" to false,
                    "message" to "Identificação de Transação Inválida!",
                    "data" to null
                ))
                return
            }

            // Validação de Tipo de Estorno
            if (voidType != PlugPag.VOID_PAYMENT && voidType != PlugPag.VOID_QRCODE) {
                result.success(mapOf(
                    "success" to false,
                    "message" to "Tipo de Estorno Inválido!",
                    "data" to null
                ))
                return
            }

            val voidData = PlugPagVoidData(
                transactionCode = transactionCode,
                transactionId = transactionId,
                printReceipt = printReceipt,
                voidType = voidType
            )

            plugPag.doAsyncVoidPayment(voidData, object : PlugPagPaymentListener {

                override fun onPaymentProgress(eventData: PlugPagEventData) {
                    CoroutineHelper.launchMain(scope) {
                        logger.info("voidPayment (onPaymentProgress)", "Realizando Estorno | Id: ${eventData.eventCode} | ${eventData.customMessage}")
                        plugPagChannel?.invokeMethod("onPaymentProgress", mapOf(
                            "eventCode" to eventData.eventCode,
                            "message" to eventData.customMessage,
                            "data" to null
                        ))
                    }
                }

                override fun onSuccess(transactionResult: PlugPagTransactionResult) {
                    CoroutineHelper.launchMain(scope) {
                        val map = transactionResult.toMap()
                        logger.info("voidPayment (onSuccess)", "Estorno Realizado | Id: ${transactionResult.transactionId}")
                        result.success(mapOf(
                            "success" to true,
                            "message" to "Estorno Realizado com Sucesso!",
                            "data" to map
                        ))
                    }
                }

                override fun onError(transactionResult: PlugPagTransactionResult) {
                    CoroutineHelper.launchMain(scope) {
                        val map = transactionResult.toMap()
                        if (abortRequested) {
                            logger.info("voidPayment (onError)", "Estorno Cancelado pelo Usuário | Id: ${transactionResult.errorCode} | Message: ${transactionResult.message}")
                            result.success(mapOf(
                                "success" to false,
                                "message" to "Estorno Cancelado pelo Usuário!",
                                "data" to map
                            ))
                        } else {
                            logger.error("voidPayment (onError)", "Erro no Estorno | Id: ${transactionResult.errorCode} | Message: ${transactionResult.message}")
                            result.success(mapOf(
                                "success" to false,
                                "message" to "${transactionResult.message} (${transactionResult.errorCode})",
                                "data" to map
                            ))
                        }
                    }
                }

                override fun onPrinterSuccess(printerResult: PlugPagPrintResult) {
                    CoroutineHelper.launchMain(scope) {
                        logger.info("voidPayment (onPrinterSuccess)", "Impressão de Recibo com Sucesso | Id: ${printerResult.errorCode}")
                    }
                }

                override fun onPrinterError(printerResult: PlugPagPrintResult) {
                    CoroutineHelper.launchMain(scope) {
                        logger.warn("voidPayment (onPrinterError)", "Erro na Impressão do Recibo | Id: ${printerResult.errorCode}")
                    }
                }
            })
        } catch (e: Exception) {
            CoroutineHelper.launchMain(scope) {
                logger.error("voidPayment (Exception)", "Erro ao Realizar Estorno: ${e.message}")
                result.success(mapOf(
                    "success" to false,
                    "message" to "Erro Fatal ao Realizar Estorno!",
                    "data" to null
                ))
            }
        }
    }

    /** Busca a Última Transação Aprovada **/
    fun getLastTransaction(result: MethodChannel.Result) {
        try {
            plugPag.asyncGetLastApprovedTransaction(object : PlugPagLastTransactionListener {
                override fun onRequestedLastTransaction(transactionResult: PlugPagTransactionResult) {
                    CoroutineHelper.launchMain(scope) {
                        val map = transactionResult.toMap()
                        logger.info("getLastTransaction (onRequestedLastTransaction)", "Última Transação | Id: ${transactionResult.transactionId}")
                        result.success(mapOf(
                            "success" to true,
                            "message" to "Última Transação encontrada com Sucesso!",
                            "data" to map
                        ))
                    }
                }

                override fun onError(transactionResult: PlugPagTransactionResult) {
                    CoroutineHelper.launchMain(scope) {
                        val map = transactionResult.toMap()
                        logger.error("getLastTransaction (onError)", "Erro ao Buscar Última Transação | Id: ${transactionResult.errorCode} | Message: ${transactionResult.message}")
                        result.success(mapOf(
                            "success" to false,
                            "message" to "${transactionResult.message} (${transactionResult.errorCode})",
                            "data" to map
                        ))
                    }
                }
            })
        } catch (e: Exception) {
            abortRequested = false
            CoroutineHelper.launchMain(scope) {
                logger.error("getLastTransaction (Exception)", "Erro ao Buscar Última Transação: ${e.message}")
                result.success(mapOf(
                    "success" to false,
                    "message" to "Erro Fatal ao Buscar Última Transação!",
                    "data" to null
                ))
            }
        }
    }
}

/** Extensão para converter PlugPagTransactionResult em Map<String, Any?> para envio ao Flutter **/
fun PlugPagTransactionResult.toMap(): Map<String, Any?> {
    return mapOf(
        "message" to message,
        "errorCode" to errorCode,
        "transactionCode" to transactionCode,
        "transactionId" to transactionId,
        "date" to date,
        "time" to time,
        "hostNsu" to hostNsu,
        "cardBrand" to cardBrand,
        "bin" to bin,
        "holder" to holder,
        "userReference" to userReference,
        "terminalSerialNumber" to terminalSerialNumber,
        "amount" to amount,
        "availableBalance" to availableBalance,
        "cardApplication" to cardApplication,
        "label" to label,
        "holderName" to holderName,
        "extendedHolderName" to extendedHolderName,
        "cardIssuerNationality" to cardIssuerNationality?.name,
        "result" to result,
        "readerModel" to readerModel,
        "nsu" to nsu,
        "autoCode" to autoCode,
        "installments" to installments,
        "originalAmount" to originalAmount,
        "buyerName" to buyerName,
        "paymentType" to paymentType,
        "typeTransaction" to typeTransaction,
        "appIdentification" to appIdentification,
        "cardHash" to cardHash,
        "preAutoDueDate" to preAutoDueDate,
        "preAutoOriginalAmount" to preAutoOriginalAmount,
        "userRegistered" to userRegistered,
        "accumulatedValue" to accumulatedValue,
        "consumerIdentification" to consumerIdentification,
        "currentBalance" to currentBalance,
        "consumerPhoneNumber" to consumerPhoneNumber,
        "clubePagScreensIds" to clubePagScreensIds,
        "partialPayPartiallyAuthorizedAmount" to partialPayPartiallyAuthorizedAmount,
        "partialPayRemainingAmount" to partialPayRemainingAmount,
        "pixTxIdCode" to pixTxIdCode
    )
}