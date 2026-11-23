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

/**
 * Gerencia todas as operações de pagamento: venda, cancelamento, estorno e última transação.
 * Cada operação existe em duas versões: síncrona (`doPayment`, responde uma vez no fim) e
 * assíncrona (`doAsyncPayment`, usa listeners do Wrapper e envia progresso ao Flutter).
 * Valores chegam do Dart em Reais e são convertidos para centavos antes de ir ao Wrapper.
 */
class PaymentManager(
    private val plugPag: PlugPag,
    private val scope: CoroutineScope,
    private val receiptManager: ReceiptManager,
    /** Canal do plugin, usado para enviar o progresso (onPaymentProgress) ao Flutter. Recebido pelo construtor
     *  (e não por variável estática) para não vazar entre engines Flutter nem depois do detach. */
    private val channel: MethodChannel
) {

    companion object {
        /** Tag utilizada nos logs */
        private const val TAG = "PaymentManager"
    }

    /** Envia ao Flutter um evento de progresso da maquininha (ex.: "aproxime o cartão") como `onPaymentProgress` **/
    private fun sendProgress(step: String, eventCode: Int, message: String?) {
        CoroutineHelper.launchMain(scope) {
            logger.info(step, "Evento: $eventCode | $message")
            channel.invokeMethod("onPaymentProgress", mapOf("eventCode" to eventCode, "message" to message, "data" to null))
        }
    }

    /** Responde uma falha de validação ao Flutter (nada é enviado à maquininha) **/
    private fun replyInvalid(result: MethodChannel.Result, message: String) {
        logger.warn("validação", message)
        result.success(mapOf("success" to false, "message" to message, "data" to null))
    }

    /**
     * Lê e valida os dados de pagamento (usado pela venda síncrona e pela assíncrona).
     * Valores chegam em Reais e viram centavos. Regras: mínimo R$ 1,00; userReference com 1 a 10 caracteres
     * alfanuméricos (outros caracteres são removidos); "à vista" usa a quantidade sentinela do Wrapper e um
     * parcelado sem quantidade volta a ser à vista; parcelado precisa de pelo menos 2 parcelas.
     * Se algo for inválido, já responde a falha ao Flutter e devolve null.
     **/
    private fun buildPaymentData(call: MethodCall, result: MethodChannel.Result): PlugPagPaymentData? {
        val amount = call.argument<Double>("amount") ?: 0.0
        val amountInCents = BigDecimal.valueOf(amount).multiply(BigDecimal(100)).setScale(0, RoundingMode.HALF_UP).toInt()
        val type = call.argument<Int>("type") ?: PlugPag.TYPE_CREDITO
        var installmentType = call.argument<Int>("installmentType") ?: PlugPag.INSTALLMENT_TYPE_A_VISTA
        var installments = call.argument<Int>("installments") ?: PlugPag.A_VISTA_INSTALLMENT_QUANTITY
        val userReference = (call.argument<String>("userReference") ?: "").replace(Regex("[^A-Za-z0-9]"), "")
        val printReceipt = call.argument<Boolean>("printReceipt") ?: false

        if (amountInCents < 100) return null.also { replyInvalid(result, "Valor Inválido para Pagamento!") }
        if (userReference.isEmpty() || userReference.length > 10) return null.also { replyInvalid(result, "Identificação do Cliente Inválida!") }

        if (installmentType == PlugPag.INSTALLMENT_TYPE_A_VISTA && installments != PlugPag.A_VISTA_INSTALLMENT_QUANTITY)
            installments = PlugPag.A_VISTA_INSTALLMENT_QUANTITY
        if (installmentType != PlugPag.INSTALLMENT_TYPE_A_VISTA && installments == PlugPag.A_VISTA_INSTALLMENT_QUANTITY)
            installmentType = PlugPag.INSTALLMENT_TYPE_A_VISTA
        if (installmentType != PlugPag.INSTALLMENT_TYPE_A_VISTA && installments < 2) return null.also { replyInvalid(result, "Número de Parcelas Inválido!") }

        return PlugPagPaymentData(
            type = type,
            amount = amountInCents,
            installmentType = installmentType,
            installments = installments,
            userReference = userReference,
            printReceipt = printReceipt,
            partialPay = false,
            isCarne = false
        )
    }

    /**
     * Lê e valida os dados de estorno (usado pelo estorno síncrono e pelo assíncrono): [transactionCode] e
     * [transactionId] da venda original são obrigatórios e o tipo deve ser VOID_PAYMENT ou VOID_QRCODE.
     * Se algo for inválido, já responde a falha ao Flutter e devolve null.
     **/
    private fun buildVoidData(call: MethodCall, result: MethodChannel.Result): PlugPagVoidData? {
        val transactionCode = call.argument<String>("transactionCode") ?: ""
        val transactionId = call.argument<String>("transactionId") ?: ""
        val printReceipt = call.argument<Boolean>("printReceipt") ?: false
        val voidType = call.argument<Int>("voidType") ?: PlugPag.VOID_PAYMENT

        if (transactionCode.isEmpty() || transactionId.isEmpty()) return null.also { replyInvalid(result, "Identificação de Transação Inválida!") }
        if (voidType != PlugPag.VOID_PAYMENT && voidType != PlugPag.VOID_QRCODE) return null.also { replyInvalid(result, "Tipo de Estorno Inválido!") }

        return PlugPagVoidData(transactionCode = transactionCode, transactionId = transactionId, printReceipt = printReceipt, voidType = voidType)
    }

    /** Logger personalizado com TAG para identificar a Origem **/
    private val logger = Logger(TAG)

    /** Variável para indicar se o cancelamento foi solicitado **/
    /**
     * Indica se o cancelamento foi solicitado (@Volatile: lido/escrito por threads diferentes: IO e Main).
     * Usado no onError/resposta final para diferenciar "cancelado pelo usuário" de "erro".
     * É zerado no início de cada operação de pagamento ou estorno.
     **/
    @Volatile private var abortRequested = false

    /**
     * Executa o Pagamento de forma Síncrona: a chamada ao Wrapper bloqueia uma thread de IO
     * e o resultado final é enviado uma única vez ao Flutter (na Main Thread).
     * Valores e parcelas são validados antes; se inválidos, nada é enviado à maquininha.
     **/
    fun doPayment(call: MethodCall, result: MethodChannel.Result) {

        logger.info("PlugPag Instance (doPayment)", plugPag.hashCode().toString())

        abortRequested = false

        val paymentData = buildPaymentData(call, result) ?: return

        // Reaplica as ações de impressão (setPrintActionListener) antes de cada venda
        receiptManager.reapplyPrintActionListener()

        // Progresso da maquininha (ex.: "aproxime o cartão") é repassado ao Dart como onPaymentProgress
        plugPag.setEventListener(object : PlugPagEventListener {
            override fun onEvent(data: PlugPagEventData) = sendProgress("doPayment (onEvent)", data.eventCode, data.customMessage)
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
                    } else if (abortRequested) {
                        // Mesma mensagem da versão assíncrona quando o próprio App pediu o cancelamento
                        logger.info("doPayment (onAbort)", "Pagamento Cancelado pelo Usuário | Code: ${transactionResult.errorCode}")
                        result.success(mapOf("success" to false, "message" to "Pagamento Cancelado pelo Usuário!", "data" to map))
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

    /**
     * Executa o Pagamento de forma Assíncrona: o Wrapper chama os listeners (progresso, sucesso, erro
     * e impressão) e o resultado só é enviado ao Flutter no fim. Mesmas validações da versão síncrona.
     * O subscriber é liberado (`disposeSubscriber`) somente no fim, nunca no progresso.
     **/
    fun doAsyncPayment(call: MethodCall, result: MethodChannel.Result) {
        logger.info("PlugPag Instance (doAsyncPayment)", plugPag.hashCode().toString())

        try {
            abortRequested = false

            val paymentData = buildPaymentData(call, result) ?: return

            receiptManager.reapplyPrintActionListener()

            plugPag.doAsyncPayment(paymentData, object : PlugPagPaymentListener {
                // IMPORTANTE: não chamar disposeSubscriber() no progresso. Ele cancela a operação em andamento
                // e o resultado final (onSuccess/onError) nunca chegaria ao Flutter.
                override fun onPaymentProgress(eventData: PlugPagEventData) =
                    sendProgress("doAsyncPayment (onPaymentProgress)", eventData.eventCode, eventData.customMessage)

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

    /**
     * Solicita o Cancelamento de Transação de forma Síncrona. Só funciona enquanto a maquininha aceita
     * cancelar (o Dart libera isso pelo onPaymentProgress). Marca [abortRequested] para o fluxo de pagamento
     * reconhecer o cancelamento; se o Wrapper recusar, a flag volta a false.
     **/
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
                            "message" to errorMessage,
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

    /**
     * Estorna Pagamento de forma Síncrona. [transactionCode] e [transactionId] identificam a venda original
     * (são obrigatórios) e [voidType] deve ser VOID_PAYMENT ou VOID_QRCODE.
     **/
    fun voidPayment(call: MethodCall, result: MethodChannel.Result) {
        logger.info("PlugPag Instance (voidPayment)", plugPag.hashCode().toString())

        abortRequested = false

        val voidData = buildVoidData(call, result) ?: return

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

            val voidData = buildVoidData(call, result) ?: return

            plugPag.doAsyncVoidPayment(voidData, object : PlugPagPaymentListener {
                // IMPORTANTE: não chamar disposeSubscriber() no progresso. Ele cancela a operação em andamento
                // e o resultado final (onSuccess/onError) nunca chegaria ao Flutter.
                override fun onPaymentProgress(eventData: PlugPagEventData) =
                    sendProgress("asyncVoidPayment (onPaymentProgress)", eventData.eventCode, eventData.customMessage)

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
            // Não mexe em abortRequested: a consulta não tem relação com um pagamento que possa estar em andamento
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

/**
 * Extensão para converter PlugPagTransactionResult em Map<String, Any?> para envio ao Flutter.
 * Atenção LGPD: o Map inclui dados do portador e do cliente (holder, bin, cardHash, buyerName,
 * consumerPhoneNumber...). Não registre esse Map em logs.
 **/
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
        "pixTxIdCode" to pixTxIdCode,
        // Campos de Câmbio (DCC) do Wrapper PagSeguro
        "isDcc" to isDcc,
        "foreignAmount" to foreignAmount,
        "currencyDestinyLabel" to currencyDestinyLabel,
        "currencyOriginLabel" to currencyOriginLabel,
        "minorUnitsForeign" to minorUnitsForeign
    )
}