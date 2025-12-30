package com.takeodev.pagseguro_smart.manager

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
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagEventListener
import com.takeodev.pagseguro_smart.utils.Logger
import com.takeodev.pagseguro_smart.utils.CoroutineHelper
import java.math.BigDecimal
import java.math.RoundingMode

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

    /** Executa o Pagamento de forma Síncrona **/
    fun doPayment(call: MethodCall, result: MethodChannel.Result) {
        logger.info("PlugPag Instance (doPayment)", plugPag.hashCode().toString())

        abortRequested = false

        val amount = call.argument<Double>("amount") ?: 0.0
        val amountInCents = BigDecimal.valueOf(amount)
            .multiply(BigDecimal(100))
            .setScale(0, RoundingMode.HALF_UP)
            .toInt()

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

        plugPag.setEventListener(object : PlugPagEventListener {
            override fun onEvent(data: PlugPagEventData) {
                CoroutineHelper.launchMain(scope) {
                    logger.info("doPayment (onEvent)", "Evento: ${data.eventCode} | ${data.customMessage}")
                    plugPagChannel?.invokeMethod(
                        "onPaymentProgress", mapOf(
                            "eventCode" to data.eventCode,
                            "message" to data.customMessage,
                            "data" to null
                        )
                    )
                }
            }
        })

        CoroutineHelper.launchIO(scope) {
            try {
                val transactionResult = plugPag.doPayment(paymentData)

                CoroutineHelper.launchMain(scope) {
                    val map = transactionResult.toMap()

                    if (transactionResult.result == PlugPag.RET_OK) {
                        logger.info("doPayment (onSuccess)", "Pagamento Realizado | Id: ${transactionResult.transactionId}")
                        result.success(
                            mapOf(
                                "success" to true,
                                "message" to "Pagamento Realizado com Sucesso!",
                                "data" to map
                            )
                        )
                    } else {
                        logger.error("doPayment (onError)", "Erro no Pagamento | Code: ${transactionResult.errorCode} | Message: ${transactionResult.message}")
                        result.success(
                            mapOf(
                                "success" to false,
                                "message" to "${transactionResult.message} (${transactionResult.errorCode})",
                                "data" to map
                            )
                        )
                    }
                }
            } catch (e: Exception) {
                CoroutineHelper.launchMain(scope) {
                    logger.error("doPayment (Exception)", "Erro ao Realizar Pagamento: ${e.message}")
                    result.success(
                        mapOf(
                            "success" to false,
                            "message" to "Erro Fatal ao Realizar Pagamento!",
                            "data" to null
                        )
                    )
                }
            }
        }
    }

    /** Executa o Pagamento de forma Assíncrona **/
    fun doAsyncPayment(call: MethodCall, result: MethodChannel.Result) {
        logger.info("PlugPag Instance (doAsyncPayment)", plugPag.hashCode().toString())

        try {
            abortRequested = false

            val amount = call.argument<Double>("amount") ?: 0.0
            val amountInCents = BigDecimal.valueOf(amount)
                .multiply(BigDecimal(100))
                .setScale(0, RoundingMode.HALF_UP)
                .toInt()

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
                        logger.info("doAsyncPayment (onPaymentProgress)", "Realizando Pagamento | Id: ${eventData.eventCode} | ${eventData.customMessage}")
                        plugPagChannel?.invokeMethod(
                                "onPaymentProgress", mapOf(
                                "eventCode" to eventData.eventCode,
                                "message" to eventData.customMessage,
                                "data" to null
                            )
                        )
                        plugPag.disposeSubscriber()
                    }
                }

                override fun onSuccess(transactionResult: PlugPagTransactionResult) {
                    CoroutineHelper.launchMain(scope) {
                        val map = transactionResult.toMap()
                        logger.info("doAsyncPayment (onSuccess)", "Pagamento Realizado | Id: ${transactionResult.transactionId}")
                        result.success(mapOf(
                            "success" to true,
                            "message" to "Pagamento Realizado com Sucesso!",
                            "data" to map
                        ))
                        plugPag.disposeSubscriber()
                    }
                }

                    override fun onError(transactionResult: PlugPagTransactionResult) {
                    CoroutineHelper.launchMain(scope) {
                        val map = transactionResult.toMap()
                        if (abortRequested) {
                            logger.info("doAsyncPayment (onError)", "Pagamento Cancelado pelo Usuário | Id: ${transactionResult.errorCode} | Message: ${transactionResult.message}")
                            result.success(mapOf(
                                "success" to false,
                                "message" to "Pagamento Cancelado pelo Usuário!",
                                "data" to map
                            ))
                        } else {
                            logger.error("doAsyncPayment (onError)", "Erro no Pagamento | Id: ${transactionResult.errorCode} | Message: ${transactionResult.message}")
                            result.success(mapOf(
                                "success" to false,
                                "message" to "${transactionResult.message} (${transactionResult.errorCode})",
                                "data" to map
                            ))
                        }
                        plugPag.disposeSubscriber()
                    }
                }

                override fun onPrinterSuccess(printerResult: PlugPagPrintResult) {
                    CoroutineHelper.launchMain(scope) {
                        logger.info("doAsyncPayment (onPrinterSuccess)", "Impressão de Recibo com Sucesso | Id: ${printerResult.errorCode}")
                        plugPag.disposeSubscriber()
                    }
                }

                override fun onPrinterError(printerResult: PlugPagPrintResult) {
                    CoroutineHelper.launchMain(scope) {
                        logger.warn("doAsyncPayment (onPrinterError)", "Erro na Impressão do Recibo | Id: ${printerResult.errorCode}")
                        plugPag.disposeSubscriber()
                    }
                }
            })
        } catch (e: Exception) {
            CoroutineHelper.launchMain(scope) {
                logger.error("doAsyncPayment (Exception)", "Erro ao Realizar Pagamento: ${e.message}")
                result.success(mapOf(
                    "success" to false,
                    "message" to "Erro Fatal ao Realizar Pagamento!",
                    "data" to null
                ))
                plugPag.disposeSubscriber()
            }
        }
    }

    /** Solicita o Cancelamento de Transação de forma Síncrona **/
    fun abortTransaction(result: MethodChannel.Result) {
        logger.info("PlugPag Instance (abortTransaction)", plugPag.hashCode().toString())

        abortRequested = true

        CoroutineHelper.launchIO(scope) {
            try {
                val abortResult = plugPag.abort()

                CoroutineHelper.launchMain(scope) {
                    abortRequested = abortResult.result == PlugPag.RET_OK

                    if (abortRequested) {
                        logger.info("abortTransaction (abort)", "Solicitado Cancelamento")
                        result.success(
                            mapOf(
                                "success" to true,
                                "message" to "Solicitado Cancelamento",
                                "data" to null
                            )
                        )
                    } else {
                        logger.warn("abortTransaction (abort)", "Falha ao Cancelar Transação")
                        result.success(
                            mapOf(
                                "success" to false,
                                "message" to "Falha ao Cancelar Transação (${abortResult.result})",
                                "data" to null
                            )
                        )
                    }
                }
            } catch (e: Exception) {
                abortRequested = false

                CoroutineHelper.launchMain(scope) {
                    logger.error("abortTransaction (Exception)", "Erro ao Cancelar Transação: ${e.message}")
                    result.success(
                        mapOf(
                            "success" to false,
                            "message" to "Erro ao Cancelar Transação!",
                            "data" to null
                        )
                    )
                }
            }
        }
    }

    /** Solicita o Cancelamento de Transação de forma Assíncrona **/
    fun asyncAbortTransaction(result: MethodChannel.Result) {
        logger.info("PlugPag Instance (asyncAbortTransaction)", plugPag.hashCode().toString())

        try {
            abortRequested = true
            plugPag.asyncAbort(object : PlugPagAbortListener {
                override fun onAbortRequested(abortResult: Boolean) {
                    CoroutineHelper.launchMain(scope) {
                        abortRequested = abortResult
                        if (abortResult) {
                            logger.info("asyncAbortTransaction (onAbortRequested)", "Solicitado Cancelamento")
                            result.success(mapOf(
                                "success" to true,
                                "message" to "Solicitado Cancelamento",
                                "data" to null
                            ))
                        } else {
                            logger.warn("asyncAbortTransaction (onAbortRequested)", "Falha ao Solicitar Cancelamento")
                            result.success(mapOf(
                                "success" to false,
                                "message" to "Falha ao Solicitar Cancelamento",
                                "data" to null
                            ))
                        }
                        plugPag.disposeSubscriber()
                    }
                }

                override fun onError(errorMessage: String) {
                    CoroutineHelper.launchMain(scope) {
                        abortRequested = false
                        logger.error("asyncAbortTransaction (onError)", "Erro ao Cancelar Transação: $errorMessage")
                        result.success(mapOf(
                            "success" to false,
                            "message" to "$errorMessage",
                            "data" to null
                        ))
                        plugPag.disposeSubscriber()
                    }
                }
            })
        } catch (e: Exception) {
            abortRequested = false
            CoroutineHelper.launchMain(scope) {
                logger.error("asyncAbortTransaction (Exception)", "Erro ao Solicitar Cancelamento: ${e.message}")
                result.success(mapOf(
                    "success" to false,
                    "message" to "Erro Fatal ao Solicitar Cancelamento!",
                    "data" to null
                ))
                plugPag.disposeSubscriber()
            }
        }
    }

    /** Estorna Pagamento de forma Síncrona **/
    fun voidPayment(call: MethodCall, result: MethodChannel.Result) {
        logger.info("PlugPag Instance (voidPayment)", plugPag.hashCode().toString())

        abortRequested = false

        val transactionCode = call.argument<String>("transactionCode") ?: ""
        val transactionId = call.argument<String>("transactionId") ?: ""
        val printReceipt = call.argument<Boolean>("printReceipt") ?: false
        val voidType = call.argument<Int>("voidType") ?: PlugPag.VOID_PAYMENT

        // Validação de Código
        if (transactionCode.isEmpty()) {
            logger.warn("transactionCode.isEmpty()", "Código da Transação Vazio!")
            result.success(
                mapOf(
                    "success" to false,
                    "message" to "Identificação de Transação Inválida!",
                    "data" to null
                )
            )
            return
        }

        // Validação de ID
        if (transactionId.isEmpty()) {
            logger.warn("transactionId.isEmpty()", "ID da Transação Vazio!")
            result.success(
                mapOf(
                    "success" to false,
                    "message" to "Identificação de Transação Inválida!",
                    "data" to null
                )
            )
            return
        }

        // Validação de Tipo
        if (voidType != PlugPag.VOID_PAYMENT && voidType != PlugPag.VOID_QRCODE) {
            result.success(
                mapOf(
                    "success" to false,
                    "message" to "Tipo de Estorno Inválido!",
                    "data" to null
                )
            )
            return
        }

        val voidData = PlugPagVoidData(
            transactionCode = transactionCode,
            transactionId = transactionId,
            printReceipt = printReceipt,
            voidType = voidType
        )

        // Execução Síncrona → fora da main thread
        CoroutineHelper.launchIO(scope) {
            try {
                val transactionResult = plugPag.voidPayment(voidData)

                CoroutineHelper.launchMain(scope) {
                    val map = transactionResult.toMap()

                    if (transactionResult.result == PlugPag.RET_OK) {
                        logger.info("voidPayment (onSuccess)", "Estorno Realizado | Id: ${transactionResult.transactionId}")
                        result.success(
                            mapOf(
                                "success" to true,
                                "message" to "Estorno Realizado com Sucesso!",
                                "data" to map
                            )
                        )
                    } else {
                        if (abortRequested) {
                            logger.info("voidPayment (onAbort)", "Estorno Cancelado pelo Usuário | Id: ${transactionResult.errorCode}")
                            result.success(
                                mapOf(
                                    "success" to false,
                                    "message" to "Estorno Cancelado pelo Usuário!",
                                    "data" to map
                                )
                            )
                        } else {
                            logger.error("voidPayment (onError)", "Erro no Estorno | Id: ${transactionResult.errorCode} | Message: ${transactionResult.message}")
                            result.success(
                                mapOf(
                                    "success" to false,
                                    "message" to "${transactionResult.message} (${transactionResult.errorCode})",
                                    "data" to map
                                )
                            )
                        }
                    }
                }
            } catch (e: Exception) {
                CoroutineHelper.launchMain(scope) {
                    logger.error("voidPayment (Exception)", "Erro ao Realizar Estorno: ${e.message}")
                    result.success(
                        mapOf(
                            "success" to false,
                            "message" to "Erro ao Realizar Estorno!",
                            "data" to null
                        )
                    )
                }
            }
        }
    }

    /** Estorna Pagamento de forma Assíncrona **/
    fun asyncVoidPayment(call: MethodCall, result: MethodChannel.Result) {
        logger.info("PlugPag Instance (asyncVoidPayment)", plugPag.hashCode().toString())

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
                        logger.info("asyncVoidPayment (onPaymentProgress)", "Realizando Estorno | Id: ${eventData.eventCode} | ${eventData.customMessage}")
                        plugPagChannel?.invokeMethod(
                            "onPaymentProgress", mapOf(
                                "eventCode" to eventData.eventCode,
                                "message" to eventData.customMessage,
                                "data" to null
                            )
                        )
                        plugPag.disposeSubscriber()
                    }
                }

                override fun onSuccess(transactionResult: PlugPagTransactionResult) {
                    CoroutineHelper.launchMain(scope) {
                        val map = transactionResult.toMap()
                        logger.info("asyncVoidPayment (onSuccess)", "Estorno Realizado | Id: ${transactionResult.transactionId}")
                        result.success(mapOf(
                            "success" to true,
                            "message" to "Estorno Realizado com Sucesso!",
                            "data" to map
                        ))
                        plugPag.disposeSubscriber()
                    }
                }

                override fun onError(transactionResult: PlugPagTransactionResult) {
                    CoroutineHelper.launchMain(scope) {
                        val map = transactionResult.toMap()
                        if (abortRequested) {
                            logger.info("asyncVoidPayment (onError)", "Estorno Cancelado pelo Usuário | Id: ${transactionResult.errorCode} | Message: ${transactionResult.message}")
                            result.success(mapOf(
                                "success" to false,
                                "message" to "Estorno Cancelado pelo Usuário!",
                                "data" to map
                            ))
                        } else {
                            logger.error("asyncVoidPayment (onError)", "Erro no Estorno | Id: ${transactionResult.errorCode} | Message: ${transactionResult.message}")
                            result.success(mapOf(
                                "success" to false,
                                "message" to "${transactionResult.message} (${transactionResult.errorCode})",
                                "data" to map
                            ))
                        }
                        plugPag.disposeSubscriber()
                    }
                }

                override fun onPrinterSuccess(printerResult: PlugPagPrintResult) {
                    CoroutineHelper.launchMain(scope) {
                        logger.info("asyncVoidPayment (onPrinterSuccess)", "Impressão de Recibo com Sucesso | Id: ${printerResult.errorCode}")
                        plugPag.disposeSubscriber()
                    }
                }

                override fun onPrinterError(printerResult: PlugPagPrintResult) {
                    CoroutineHelper.launchMain(scope) {
                        logger.warn("asyncVoidPayment (onPrinterError)", "Erro na Impressão do Recibo | Id: ${printerResult.errorCode}")
                        plugPag.disposeSubscriber()
                    }
                }
            })
        } catch (e: Exception) {
            CoroutineHelper.launchMain(scope) {
                logger.error("asyncVoidPayment (Exception)", "Erro ao Realizar Estorno: ${e.message}")
                result.success(mapOf(
                    "success" to false,
                    "message" to "Erro ao Realizar Estorno!",
                    "data" to null
                ))
                plugPag.disposeSubscriber()
            }
        }
    }

    /** Busca a Última Transação Aprovada de forma Síncrona **/
    fun getLastTransaction(result: MethodChannel.Result) {
        logger.info("PlugPag Instance (getLastTransaction)", plugPag.hashCode().toString())

        CoroutineHelper.launchIO(scope) {
            try {
                val transactionResult = plugPag.getLastApprovedTransaction()
                val map = transactionResult.toMap()

                CoroutineHelper.launchMain(scope) {
                    if (transactionResult.result == PlugPag.RET_OK) {
                        logger.info("getLastTransaction (getLastApprovedTransaction)", "Última Transação | Id: ${transactionResult.transactionId}")
                        result.success(
                            mapOf(
                                "success" to true,
                                "message" to "Última Transação encontrada com Sucesso!",
                                "data" to map
                            )
                        )
                    } else {
                        logger.error("getLastTransaction (getLastApprovedTransaction)", "Erro ao Buscar Última Transação | Id: ${transactionResult.errorCode} | Message: ${transactionResult.message}")
                        result.success(
                            mapOf(
                                "success" to false,
                                "message" to "${transactionResult.message} (${transactionResult.errorCode})",
                                "data" to map
                            )
                        )
                    }
                }
            } catch (e: Exception) {
                CoroutineHelper.launchMain(scope) {
                    logger.error("getLastTransaction (Exception)", "Erro ao Buscar Última Transação: ${e.message}")
                    result.success(
                        mapOf(
                            "success" to false,
                            "message" to "Erro ao Buscar Última Transação!",
                            "data" to null
                        )
                    )
                }
            }
        }
    }

    /** Busca a Última Transação Aprovada de forma Assíncrona **/
    fun asyncGetLastTransaction(result: MethodChannel.Result) {
        logger.info("PlugPag Instance (asyncGetLastTransaction)", plugPag.hashCode().toString())

        try {
            plugPag.asyncGetLastApprovedTransaction(object : PlugPagLastTransactionListener {
                override fun onRequestedLastTransaction(transactionResult: PlugPagTransactionResult) {
                    CoroutineHelper.launchMain(scope) {
                        val map = transactionResult.toMap()
                        logger.info("asyncGetLastTransaction (onRequestedLastTransaction)", "Última Transação | Id: ${transactionResult.transactionId}")
                        result.success(mapOf(
                            "success" to true,
                            "message" to "Última Transação encontrada com Sucesso!",
                            "data" to map
                        ))
                        plugPag.disposeSubscriber()
                    }
                }

                override fun onError(transactionResult: PlugPagTransactionResult) {
                    CoroutineHelper.launchMain(scope) {
                        val map = transactionResult.toMap()
                        logger.error("asyncGetLastTransaction (onError)", "Erro ao Buscar Última Transação | Id: ${transactionResult.errorCode} | Message: ${transactionResult.message}")
                        result.success(mapOf(
                            "success" to false,
                            "message" to "${transactionResult.message} (${transactionResult.errorCode})",
                            "data" to map
                        ))
                        plugPag.disposeSubscriber()
                    }
                }
            })
        } catch (e: Exception) {
            abortRequested = false
            CoroutineHelper.launchMain(scope) {
                logger.error("asyncGetLastTransaction (Exception)", "Erro ao Buscar Última Transação: ${e.message}")
                result.success(mapOf(
                    "success" to false,
                    "message" to "Erro ao Buscar Última Transação!",
                    "data" to null
                ))
                plugPag.disposeSubscriber()
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