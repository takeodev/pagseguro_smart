package com.takeodev.pagseguro_smart.manager

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
import br.com.uol.pagseguro.plugpagservice.wrapper.listeners.PlugPagPrintActionListener
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagPrintActionResult
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagTransactionResult
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagCustomPrinterLayout
import com.takeodev.pagseguro_smart.utils.Util
import com.takeodev.pagseguro_smart.utils.Logger
import com.takeodev.pagseguro_smart.utils.CoroutineHelper


/**
 * Gerencia todas as operações de impressão e recibos: reimpressão (cliente e loja), envio por SMS,
 * configuração do que fazer ao fim de uma venda (pergunta, SMS, impressão direta) e estilo do recibo.
 **/
class ReceiptManager(private val plugPag: PlugPag, private val scope: CoroutineScope) {

    companion object {
        /** Tag utilizada nos logs */
        private const val TAG = "ReceiptManager"
    }

    /** Logger personalizado com TAG para identificar a Origem **/
    private val logger = Logger(TAG)

    /** Variáveis para Impressão de Recibo do Cliente **/
    private var changedReceipt: Boolean = false
    private var askReceipt: Boolean = true
    private var smsReceipt: Boolean = false
    private var directReceipt: Boolean = false
        
    /**
     * Listener de Impressão de Recibo do Cliente, chamado pelo Wrapper ao fim de cada venda.
     * Ordem de prioridade (a primeira flag ligada vence): `askReceipt` (pergunta ao cliente), `smsReceipt`
     * (envia por SMS; sem telefone válido, cai na pergunta), `directReceipt` (imprime sem perguntar).
     * Se nenhuma estiver ligada, o recibo é dispensado.
     **/
    private val printListener = object : PlugPagPrintActionListener {
        override fun onPrint(
            phoneNumber: String?,
            transactionResult: PlugPagTransactionResult?,
            onFinishActions: PlugPagPrintActionListener.OnFinishPlugPagPrintActions?
        ) {
            val transactionId = transactionResult?.transactionId
            logger.info("printListener (onPrint)", "Interceptando Impressão de Recibo | Id: $transactionId")
            // Diagnóstico sem dados pessoais (LGPD): só presença/ausência dos campos, nunca os valores de telefone/cartão.
            // "conexão" = PlugPag.paymentConnection, por onde o Wrapper envia a ação escolhida abaixo; nula = ação perdida.
            logger.info(
                "printListener (onPrint, diagnóstico)",
                "result: ${transactionResult?.result} | errorCode: ${transactionResult?.errorCode} | " +
                    "transactionCode: ${!transactionResult?.transactionCode.isNullOrBlank()} | transactionId: ${!transactionId.isNullOrBlank()} | " +
                    "tipo: ${transactionResult?.typeTransaction} | telefone: ${!phoneNumber.isNullOrBlank()} | " +
                    "onFinishActions: ${onFinishActions != null} | conexão: ${plugPag.paymentConnection != null} | thread: ${Thread.currentThread().name}"
            )
            logger.info("printListener (onPrint)", "askReceipt: ${this@ReceiptManager.askReceipt} | smsReceipt: ${this@ReceiptManager.smsReceipt} | directReceipt: ${this@ReceiptManager.directReceipt}")

            when {
                this@ReceiptManager.askReceipt -> {
                    logger.info("printListener (onPrint, showPopup)", "Diálogo para Impressão de Recibo.")
                    // Exibe a tela de diálogo de envio ou impressão de comprovante fornecida pela PlugPagService.
                    onFinishActions?.showPopup(plugPag)
                }
                this@ReceiptManager.smsReceipt -> {
                    logger.info("printListener (onPrint, sendSMS)", "Envio de Recibo via SMS.")
                    if (!phoneNumber.isNullOrBlank()) {
                        // Realiza o envio do comprovante de transação (via do cliente) por SMS.
                        onFinishActions?.sendSMS(plugPag, phoneNumber)
                    } else {
                        logger.warn("printListener (onPrint, phoneNumber.isNullOrBlank)", "Número de Telefone Inválido para SMS!")
                        // Exibe a tela de diálogo de envio ou impressão de comprovante fornecida pela PlugPagService.
                        onFinishActions?.showPopup(plugPag)
                    }
                }
                this@ReceiptManager.directReceipt -> {
                    logger.info("printListener (onPrint, doPrint)", "Impressão Direta (Sem Perguntar).")
                    // Realiza a impressão do comprovante de transação (via do cliente).
                    onFinishActions?.doPrint(plugPag)
                }
                else -> {
                    logger.info("printListener (onPrint, doNothing)", "Dispensa Impressão de Recibo.")
                    // Dispensa o envio e a impressão do comprovante (via do cliente).
                    onFinishActions?.doNothing(plugPag)
                }
            }
        }

        override fun onError(exception: PlugPagException?) {
            logger.error("printListener (onError)", "Erro na Intercepção de Impressão de Recibo: ${exception?.message}")
        }
    }

    /** Reimpressão de Recibo: Via do Cliente de forma Síncrona **/
    fun reprintCustomerReceipt(result: MethodChannel.Result) {
        logger.info("PlugPag Instance (reprintCustomerReceipt)", plugPag.hashCode().toString())

        CoroutineHelper.launchIO(scope) {
            try {
                val printResult = plugPag.reprintCustomerReceipt()

                CoroutineHelper.launchMain(scope) {
                    if (printResult.result == PlugPag.RET_OK) {
                        logger.info("reprintCustomerReceipt (onSuccess)", "Reimpresso Recibo")
                        val map = mapOf(
                            "result" to printResult.result,
                            "steps" to printResult.steps
                        )
                        result.success(
                            mapOf(
                                "success" to true,
                                "message" to "Reimpresso Recibo!",
                                "data" to map
                            )
                        )
                    } else {
                        logger.error("reprintCustomerReceipt (onError)", "Erro na Reimpressão de Recibo | Id: ${printResult.errorCode}")
                        result.success(
                            mapOf(
                                "success" to false,
                                "message" to "${printResult.message} (${printResult.errorCode})",
                                "data" to null
                            )
                        )
                    }
                }
            } catch (e: Exception) {
                CoroutineHelper.launchMain(scope) {
                    logger.error("reprintCustomerReceipt (Exception)", "Erro na Reimpressão de Recibo: ${e.message}")
                    result.success(
                        mapOf(
                            "success" to false,
                            "message" to "Erro na Reimpressão de Recibo!",
                            "data" to null
                        )
                    )
                }
            }
        }
    }

    /** Reimpressão de Recibo: Via do Cliente de forma Assíncrona **/
    fun asyncReprintCustomerReceipt(result: MethodChannel.Result) {
        logger.info("PlugPag Instance (asyncReprintCustomerReceipt)", plugPag.hashCode().toString())

        try {
            plugPag.asyncReprintCustomerReceipt(object : PlugPagPrinterListener {
                override fun onSuccess(printResult: PlugPagPrintResult) {
                    CoroutineHelper.launchMain(scope) {
                        logger.info("asyncReprintCustomerReceipt (onSuccess)", "Reimpreso Recibo")
                        val map = mapOf(
                            "result" to printResult.result,
                            "steps" to printResult.steps
                        )
                        result.success(mapOf(
                            "success" to true,
                            "message" to "Reimpreso Recibo!",
                            "data" to map
                        ))
                        plugPag.disposeSubscriber()
                    }
                }

                override fun onError(printResult: PlugPagPrintResult) {
                    CoroutineHelper.launchMain(scope) {
                        logger.error("asyncReprintCustomerReceipt (onError)", "Erro na Reimpressão de Recibo | Id: ${printResult.errorCode}")
                        result.success(mapOf(
                            "success" to false,
                            "message" to "${printResult.message} (${printResult.errorCode})",
                            "data" to null
                        ))
                        plugPag.disposeSubscriber()
                    }
                }
            })
        } catch (e: Exception) {
            CoroutineHelper.launchMain(scope) {
                logger.error("asyncReprintCustomerReceipt (Exception)", "Erro na Reimpressão de Recibo: ${e.message}")
                result.success(mapOf(
                    "success" to false,
                    "message" to "Erro na Reimpressão de Recibo!",
                    "data" to null
                ))
                plugPag.disposeSubscriber()
            }
        }
    }

    /** Reimpressão de Recibo: Via da Loja de forma Síncrona **/
    fun reprintEstablishmentReceipt(result: MethodChannel.Result) {
        logger.info("PlugPag Instance (reprintEstablishmentReceipt)", plugPag.hashCode().toString())

        CoroutineHelper.launchIO(scope) {
            try {
                val printResult = plugPag.reprintStablishmentReceipt()

                CoroutineHelper.launchMain(scope) {
                    val map = mapOf(
                        "result" to printResult.result,
                        "steps" to printResult.steps
                    )

                    if (printResult.result == PlugPag.RET_OK) {
                        logger.info("reprintEstablishmentReceipt (onSuccess)", "Reimpresso Recibo")
                        result.success(
                            mapOf(
                                "success" to true,
                                "message" to "Reimpresso Recibo!",
                                "data" to map
                            )
                        )
                    } else {
                        logger.error("reprintEstablishmentReceipt (onError)", "Erro na Reimpressão de Recibo | Id: ${printResult.errorCode}")
                        result.success(
                            mapOf(
                                "success" to false,
                                "message" to "${printResult.message} (${printResult.errorCode})",
                                "data" to null
                            )
                        )
                    }
                }
            } catch (e: Exception) {
                CoroutineHelper.launchMain(scope) {
                    logger.error("reprintEstablishmentReceipt (Exception)", "Erro na Reimpressão de Recibo: ${e.message}")
                    result.success(
                        mapOf(
                            "success" to false,
                            "message" to "Erro na Reimpressão de Recibo!",
                            "data" to null
                        )
                    )
                }
            }
        }
    }

    /** Reimpressão de Recibo: Via da Loja de forma Assíncrona **/
    fun asyncReprintEstablishmentReceipt(result: MethodChannel.Result) {
        logger.info("PlugPag Instance (asyncReprintEstablishmentReceipt)", plugPag.hashCode().toString())

        try {
            plugPag.asyncReprintEstablishmentReceipt(object : PlugPagPrinterListener {
                override fun onSuccess(printResult: PlugPagPrintResult) {
                    CoroutineHelper.launchMain(scope) {
                        logger.info("asyncReprintEstablishmentReceipt (onSuccess)", "Reimpresso Recibo")
                        val map = mapOf(
                            "result" to printResult.result,
                            "steps" to printResult.steps
                        )
                        result.success(mapOf(
                            "success" to true,
                            "message" to "Reimpresso Recibo!",
                            "data" to map
                        ))
                        plugPag.disposeSubscriber()
                    }
                }

                override fun onError(printResult: PlugPagPrintResult) {
                    CoroutineHelper.launchMain(scope) {
                        logger.error("asyncReprintEstablishmentReceipt (onError)", "Erro na Reimpressão de Recibo | Id: ${printResult.errorCode}")
                        result.success(mapOf(
                            "success" to false,
                            "message" to "${printResult.message} (${printResult.errorCode})",
                            "data" to null
                        ))
                        plugPag.disposeSubscriber()
                    }
                }
            })
        } catch (e: Exception) {
            CoroutineHelper.launchMain(scope) {
                logger.error("asyncReprintEstablishmentReceipt (Exception)", "Erro na Reimpressão de Recibo: ${e.message}")
                result.success(mapOf(
                    "success" to false,
                    "message" to "Erro na Reimpressão de Recibo!",
                    "data" to null
                ))
                plugPag.disposeSubscriber()
            }
        }
    }

    /**
     * Envia Recibo via SMS para o telefone informado, referente à [transactionCode].
     * Atenção LGPD: o telefone é dado pessoal e não deve ir para os logs.
     **/
    fun sendReceiptSMS(call: MethodCall, result: MethodChannel.Result) {
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

        // Validação do telefone (só verifica se não está vazio)
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

        CoroutineHelper.launchIO(scope) {
            try {
                val smsReturn = plugPag.sendReceiptSMS(smsData = smsData)

                CoroutineHelper.launchMain(scope) {
                    if (smsReturn == true) {
                        logger.info("sendReceiptSMS (smsReturn == true)", "Sucesso ao Enviar SMS")
                        result.success(
                            mapOf(
                                "success" to true,
                                "message" to "Enviado SMS!",
                                "data" to null
                            )
                        )
                    } else {
                        logger.error("sendReceiptSMS (smsReturn == null || smsReturn == false)", "Falha ao Enviar SMS")
                        result.success(
                            mapOf(
                                "success" to false,
                                "message" to "Falha ao Enviar SMS.",
                                "data" to null
                            )
                        )
                    }
                }
            } catch (e: Exception) {
                CoroutineHelper.launchMain(scope) {
                    logger.error("sendReceiptSMS (PlugPagException)", "Erro ao Enviar SMS: ${e.message}")
                    result.success(mapOf(
                        "success" to false,
                        "message" to "Erro ao Enviar SMS!",
                        "data" to null
                    ))
                }
            }
        }
    }

    /**
     * ReAplica Configurações de Impressão de Recibo do Cliente.
     * Chamado pelo PaymentManager antes de cada venda para que o listener registrado seja o da configuração
     * atual. Não faz nada enquanto `setPrintActionListener` nunca tiver sido chamado ([changedReceipt] = false).
     **/
    fun reapplyPrintActionListener() {
        logger.info("PlugPag Instance (reapplyPrintActionListener)", plugPag.hashCode().toString())

        if (this.changedReceipt) {
            CoroutineHelper.launchIO(scope) {
                try {
                    val actionResult: PlugPagPrintActionResult = plugPag.setPrintActionListener(printListener)
                    if (actionResult.result == PlugPag.RET_OK) {
                        logger.info("reapplyPrintActionListener", "Reaplicada Configuração de Recibo do Cliente!")
                    } else {
                        logger.error("reapplyPrintActionListener", "Falha ao Reaplicar Configuração de Recibo do Cliente | Code: ${actionResult.result}")
                    }
                } catch (e: Exception) {
                    logger.error("reapplyPrintActionListener (Exception)", "Erro ao Reaplicar Configuração de Recibo do Cliente: ${e.message}")
                }
            }
        }
    }

    /**
     * Versão bloqueante de [reapplyPrintActionListener], para uso em thread de IO logo antes de um estorno.
     * O registro do ouvinte no serviço PagBank vale para uma operação: a venda anterior o consome (testado na GPOS780S: o
     * estorno seguinte não chamava o `onPrint` e o serviço abria o popup padrão, esperando ~15 s). Reaplicar antes do estorno
     * garante que a ação configurada seja usada. Não faz nada se `setPrintActionListener` nunca foi chamado.
     **/
    fun reapplyPrintActionListenerBlocking() {
        if (!this.changedReceipt) return
        try {
            val actionResult: PlugPagPrintActionResult = plugPag.setPrintActionListener(printListener)
            logger.info("reapplyPrintActionListenerBlocking", "Configuração de Recibo reaplicada antes do estorno | Code: ${actionResult.result}")
        } catch (e: Exception) {
            logger.error("reapplyPrintActionListenerBlocking (Exception)", "Erro ao reaplicar Configuração de Recibo: ${e.message}")
        }
    }

    /**
     * Configura Ações de Impressão de Recibo do Cliente. Guarda as três flags (askReceipt, smsReceipt,
     * directReceipt; flag ausente no argumento fica `false`) e registra o [printListener] no Wrapper.
     * Ver a prioridade entre as flags em [printListener].
     **/
    fun setPrintActionListener(call: MethodCall, result: MethodChannel.Result) {
        logger.info("PlugPag Instance (setPrintActionListener)", plugPag.hashCode().toString())

        this.askReceipt = call.argument<Boolean>("askReceipt") ?: false
        this.smsReceipt = call.argument<Boolean>("smsReceipt") ?: false
        this.directReceipt = call.argument<Boolean>("directReceipt") ?: false
        this.changedReceipt = true

        CoroutineHelper.launchIO(scope) {
            try {
                val actionResult: PlugPagPrintActionResult = plugPag.setPrintActionListener(printListener)

                CoroutineHelper.launchMain(scope) {
                    if (actionResult.result == PlugPag.RET_OK) {
                        logger.info("setPrintActionListener", "Configurado Recibo do Cliente!")
                        result.success(
                            mapOf(
                                "success" to true,
                                "message" to "Configurado Recibo do Cliente!",
                                "data" to actionResult.result
                            )
                        )
                    } else {
                        logger.error("setPrintActionListener", "Falha ao Configurar Recibo do Cliente | Code: ${actionResult.result}")
                        result.success(
                            mapOf(
                                "success" to false,
                                "message" to "Falha ao Configurar Recibo do Cliente!",
                                "data" to actionResult.result
                            )
                        )
                    }
                }
            } catch (e: Exception) {
                CoroutineHelper.launchMain(scope) {
                    logger.error("setPrintActionListener (Exception)", "Erro ao Configurar Recibo do Cliente: ${e.message}")
                    result.success(mapOf(
                        "success" to false,
                        "message" to "Erro ao Configurar Recibo do Cliente!",
                        "data" to null
                    ))
                }
            }
        }
    }

    /**
     * Define Estilo Visual (Cores e Texto) do Recibo do Cliente de forma Síncrona.
     * Cores chegam como inteiro ARGB ou texto HEX (ver [Util.callHex]).
     * `maxTimeShowPopup` = tempo máximo, em segundos, que o popup do recibo (perguntar / SMS / imprimir) fica na tela.
     * Sem valor no argumento assume 20, o mesmo padrão do Dart (setPlugPagCustomPrinterLayout).
     **/
    fun setPlugPagCustomPrinterLayout(call: MethodCall, result: MethodChannel.Result) {
        logger.info("PlugPag Instance (setPlugPagCustomPrinterLayout)", plugPag.hashCode().toString())

        val layout = PlugPagCustomPrinterLayout(
            title = Util.callString(call, "title"),
            titleColor = Util.callHex(call, "titleColor"),
            confirmTextColor = Util.callHex(call, "confirmTextColor"),
            cancelTextColor = Util.callHex(call, "cancelTextColor"),
            windowBackgroundColor = Util.callHex(call, "windowBackgroundColor"),
            buttonBackgroundColor = Util.callHex(call, "buttonBackgroundColor"),
            buttonBackgroundColorDisabled = Util.callHex(call, "buttonBackgroundColorDisabled"),
            sendSMSTextColor = Util.callHex(call, "sendSMSTextColor"),
            maxTimeShowPopup = Util.callInt(call, "maxTimeShowPopup", 20)
        )

        CoroutineHelper.launchIO(scope) {
            try {
                plugPag.setPlugPagCustomPrinterLayout(layout)

                CoroutineHelper.launchMain(scope) {
                    logger.info("setPlugPagCustomPrinterLayout", "Estilo de Recibo do Cliente Configurado!")
                    result.success(
                        mapOf(
                            "success" to true,
                            "message" to "Estilo de Recibo do Cliente Configurado!",
                            "data" to null
                        )
                    )
                }
            } catch (e: Exception) {
                CoroutineHelper.launchMain(scope) {
                    logger.error("setPlugPagCustomPrinterLayout (PlugPagException)", "Erro ao Configurar Estilo de Recibo do Cliente: ${e.message}")
                    result.success(
                        mapOf(
                            "success" to false,
                            "message" to "Erro ao Configurar Estilo de Recibo do Cliente!",
                            "data" to null
                        )
                    )
                }
            }
        }
    }
}