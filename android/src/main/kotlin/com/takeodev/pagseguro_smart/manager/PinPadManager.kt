package com.takeodev.pagseguro_smart.manager

/** ======================================================================================
Arquivo         : PinPadManager.kt
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
import br.com.uol.pagseguro.plugpagservice.wrapper.listeners.PlugPagActivationListener
import br.com.uol.pagseguro.plugpagservice.wrapper.listeners.PlugPagIsActivatedListener
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagEventData
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagInitializationResult
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagUserDataResult
import br.com.uol.pagseguro.plugpagservice.wrapper.exception.PlugPagException
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPagStyleData
import br.com.uol.pagseguro.plugpagservice.wrapper.listeners.PlugPagSetStylesListener
import com.takeodev.pagseguro_smart.utils.Util
import com.takeodev.pagseguro_smart.utils.Logger
import com.takeodev.pagseguro_smart.utils.CoroutineHelper

/** Gerencia a ativação do PinPad **/
class PinPadManager(private val plugPag: PlugPag, private val scope: CoroutineScope) {

    companion object {
        /** Tag utilizada nos logs */
        private const val TAG = "PinPadManager"
    }

    private val logger = Logger(TAG)

    /** Verifica se PinPad foi Autenticado de forma Assíncrona **/
    fun isAuthenticated(result: MethodChannel.Result) {
        CoroutineHelper.launchIO(scope) {
            try {
                val isAuth = plugPag.isAuthenticated()

                CoroutineHelper.launchMain(scope) {
                    if (isAuth) {
                        logger.info("isAuthenticated (isAuthenticated == true)", "PinPad Autenticado")
                        result.success(
                            mapOf(
                                "success" to true,
                                "message" to "PinPad Autenticado!",
                                "data" to null
                            )
                        )
                    } else {
                        logger.info("isAuthenticated (isAuthenticated == false)", "PinPad Não Autenticado")
                        result.success(
                            mapOf(
                                "success" to false,
                                "message" to "PinPad Não Autenticado!",
                                "data" to null
                            )
                        )
                    }
                }
            } catch (e: Exception) {
                CoroutineHelper.launchMain(scope) {
                    logger.error("isAuthenticated (Exception)", "Erro na Autenticação: ${e.message}")
                    result.success(
                        mapOf(
                            "success" to false,
                            "message" to "Erro na Autenticação!",
                            "data" to null
                        )
                    )
                }
            }
        }
    }

    /** Verifica se PinPad foi Autenticado de forma Assíncrona **/
    fun asyncIsAuthenticated(result: MethodChannel.Result) {
        try {
            plugPag.asyncIsAuthenticated(
                object : PlugPagIsActivatedListener {
                    override fun onIsActivated(isActivated: Boolean) {
                        CoroutineHelper.launchMain(scope) {
                            if (isActivated) {
                                logger.info("asyncIsAuthenticated (onIsActivated, isActivated == true)", "PinPad Autenticado")
                                result.success(mapOf(
                                    "success" to true,
                                    "message" to "PinPad Autenticado!",
                                    "data" to null
                                ))
                            } else {
                                logger.info("asyncIsAuthenticated (onIsActivated, isActivated == false)", "PinPad Não Autenticado")
                                result.success(mapOf(
                                    "success" to false,
                                    "message" to "PinPad Não Autenticado!",
                                    "data" to null
                                ))
                            }
                            plugPag.disposeSubscriber()
                        }
                    }

                    override fun onError(errorMessage: String) {
                        CoroutineHelper.launchMain(scope) {
                            logger.error("asyncIsAuthenticated (onError)", "Erro na Autenticação: $errorMessage")
                            result.success(mapOf(
                                "success" to false,
                                "message" to "$errorMessage",
                                "data" to null
                            ))
                            plugPag.disposeSubscriber()
                        }
                    }
                }
            )
        } catch (e: Exception) {
            CoroutineHelper.launchMain(scope) {
                logger.error("asyncIsAuthenticated (Exception)", "Erro na Autenticação: ${e.message}")
                result.success(mapOf(
                    "success" to false,
                    "message" to "Erro na Autenticação!",
                    "data" to null
                ))
                plugPag.disposeSubscriber()
            }
        }
    }

    /** Inicializa e ativa o PinPad de forma Síncrona **/
    fun initPinPad(call: MethodCall, result: MethodChannel.Result) {
        // Validação
        val code = call.argument<String>("activationCode").orEmpty()
        if (code.isEmpty()) {
            logger.warn("initPinPad (code.isEmpty())", "Fornecer Código de Ativação")
            result.success(
                mapOf(
                    "success" to false,
                    "message" to "Fornecer Código de Ativação",
                    "data" to null
                )
            )
            return
        }

        val activationData = PlugPagActivationData(activationCode = code)

        CoroutineHelper.launchIO(scope) {
            try {
                val initializationResult = plugPag.initializeAndActivatePinpad(activationData)

                CoroutineHelper.launchMain(scope) {
                    if (initializationResult.result == PlugPag.RET_OK) {
                        logger.info("initPinPad (onSuccess)", "PinPad Ativado")
                        result.success(
                            mapOf(
                                "success" to true,
                                "message" to "PinPad Ativado com Sucesso!",
                                "data" to null
                            )
                        )
                    } else {
                        logger.error("initPinPad (onError)", "Erro na Ativação | Id: ${initializationResult.errorCode}")
                        result.success(
                            mapOf(
                                "success" to false,
                                "message" to "${initializationResult.errorMessage} (${initializationResult.errorCode})",
                                "data" to null
                            )
                        )
                    }
                }
            } catch (e: Exception) {
                CoroutineHelper.launchMain(scope) {
                    logger.error("initPinPad (Exception)", "Erro ao Ativar PinPad: ${e.message}")
                    result.success(
                        mapOf(
                            "success" to false,
                            "message" to "Erro ao Ativar PinPad!",
                            "data" to null
                        )
                    )
                }
            }
        }
    }


    /** Inicializa e ativa o PinPad de forma Assíncrona **/
    fun asyncInitPinPad(call: MethodCall, result: MethodChannel.Result) {
        try {
            // Validação
            val code = call.argument<String>("activationCode").orEmpty()
            if (code.isEmpty()) {
                logger.warn("asyncInitPinPad (code.isEmpty())", "Fornecer Código de Ativação")
                result.success(mapOf(
                    "success" to false,
                    "message" to "Fornecer Código de Ativação",
                    "data" to null
                ))
                return
            }

            val activationData = PlugPagActivationData(activationCode = code)

            plugPag.doAsyncInitializeAndActivatePinpad(
                activationData,
                object : PlugPagActivationListener {
                    override fun onActivationProgress(eventData: PlugPagEventData) {
                        CoroutineHelper.launchMain(scope) {
                            logger.info("asyncInitPinPad (onActivationProgress)", "Ativando PinPad | Id: ${eventData.eventCode} | ${eventData.customMessage}")
                            plugPag.disposeSubscriber()
                        }
                    }

                    override fun onSuccess(initializationResult: PlugPagInitializationResult) {
                        CoroutineHelper.launchMain(scope) {
                            logger.info("asyncInitPinPad (onSuccess)", "PinPad Ativado")
                            result.success(mapOf(
                                "success" to true,
                                "message" to "PinPad Ativado com Sucesso!",
                                "data" to null
                            ))
                            plugPag.disposeSubscriber()
                        }
                    }

                    override fun onError(initializationResult: PlugPagInitializationResult) {
                        CoroutineHelper.launchMain(scope) {
                            logger.error("asyncInitPinPad (onError)", "Erro na Ativação | Id: ${initializationResult.errorCode}")
                            result.success(mapOf(
                                "success" to false,
                                "message" to "${initializationResult.errorMessage} (${initializationResult.errorCode})",
                                "data" to null
                            ))
                            plugPag.disposeSubscriber()
                        }
                    }
                }
            )
        } catch (e: Exception) {
            CoroutineHelper.launchMain(scope) {
                logger.error("asyncInitPinPad (Exception)", "Erro ao Ativar PinPad: ${e.message}")
                result.success(mapOf(
                    "success" to false,
                    "message" to "Erro ao Ativar PinPad!",
                    "data" to null
                ))
                plugPag.disposeSubscriber()
            }
        }
    }

    /** Coleta Dados do Usuário (Dono da Maquininha) **/
    fun getUserData(result: MethodChannel.Result) {
        CoroutineHelper.launchIO(scope) { // roda em thread de background
            try {
                val userData: PlugPagUserDataResult? = try {
                    plugPag.getUserData()
                } catch (e: Exception) {
                    null
                }

                CoroutineHelper.launchMain(scope) {
                    if (userData != null) {
                        logger.info("getUserData (userData != null)", "Sucesso ao Obter Dados do Usuário")
                        val map = userData.toMap()
                        result.success(
                            mapOf(
                                "success" to true,
                                "message" to "Coletado Dados do Usuário!",
                                "data" to map
                            )
                        )
                    } else {
                        logger.error("getUserData (userData == null)", "Falha ao Obter Dados do Usuário")
                        result.success(
                            mapOf(
                                "success" to false,
                                "message" to "Falha ao Obter Dados do Usuário.",
                                "data" to null
                            )
                        )
                    }
                }
            } catch (e: Exception) {
                CoroutineHelper.launchMain(scope) {
                    logger.error("getUserData (Exception)", "Erro ao Obter Dados do Usuário: ${e.message}")
                    result.success(
                        mapOf(
                            "success" to false,
                            "message" to "Erro ao Obter Dados do Usuário!",
                            "data" to null
                        )
                    )
                }
            }
        }
    }

    /** Busca o Número de Série da Maquininha **/
    fun getSerialNumber(result: MethodChannel.Result) {
        CoroutineHelper.launchIO(scope) {
            try {
                val serialNumber: String? = try {
                    plugPag.getSerialNumber()
                } catch (e: Exception) {
                    null
                }

                CoroutineHelper.launchMain(scope) {
                    if (serialNumber != null) {
                        logger.info("getSerialNumber (serialNumber != null)", "Sucesso ao Obter Número de Série")

                        result.success(
                            mapOf(
                                "success" to true,
                                "message" to "Coletado Número de Série!",
                                "data" to serialNumber
                            )
                        )
                    } else {
                        logger.error("getSerialNumber (serialNumber == null)", "Falha ao Obter Número de Série")
                        result.success(
                            mapOf(
                                "success" to false,
                                "message" to "Falha ao Obter Número de Série.",
                                "data" to null
                            )
                        )
                    }
                }
            } catch (e: Exception) {
                CoroutineHelper.launchMain(scope) {
                    logger.error("getSerialNumber (Exception)", "Erro ao Obter Número de Série: ${e.message}")
                    result.success(
                        mapOf(
                            "success" to false,
                            "message" to "Erro ao Obter Número de Série!",
                            "data" to null
                        )
                    )
                }
            }
        }
    }

    /** Reinicia a Maquininha **/
    fun rebootDevice(result: MethodChannel.Result) {
        CoroutineHelper.launchIO(scope) {
            try {
                plugPag.reboot()

                CoroutineHelper.launchMain(scope) {
                    logger.info("rebootDevice", "Reiniciando Maquininha")
                    result.success(
                        mapOf(
                            "success" to true,
                            "message" to "Reiniciando Maquininha!",
                            "data" to null
                        )
                    )
                }
            } catch (e: PlugPagException) {
                CoroutineHelper.launchMain(scope) {
                    logger.error("rebootDevice (PlugPagException)", "Erro ao Reiniciar Maquininha: ${e.message}")
                    result.success(
                        mapOf(
                            "success" to false,
                            "message" to "Erro ao Reiniciar Maquininha!",
                            "data" to null
                        )
                    )
                }
            }
        }
    }

    /** Verifica se o Serviço da PagSeguro está Livre **/
    fun isServiceBusy(result: MethodChannel.Result) {
        CoroutineHelper.launchIO(scope) {
            try {
                val isBusy = plugPag.isServiceBusy()

                CoroutineHelper.launchMain(scope) {
                    result.success(
                        mapOf(
                            "success" to true,
                            "message" to if (isBusy)
                                "Serviço da PagSeguro Ocupado!"
                            else
                                "Serviço da PagSeguro Livre!",
                            "data" to isBusy
                        )
                    )
                }
            } catch (e: PlugPagException) {
                CoroutineHelper.launchMain(scope) {
                    result.success(
                        mapOf(
                            "success" to false,
                            "message" to "Erro ao Verificar Serviço da PagSeguro!",
                            "data" to null
                        )
                    )
                }
            }
        }
    }

    /** Define Estilo Visual (Cores) de Janelas PagSeguro de forma Síncrona **/
    fun setStyleData(call: MethodCall, result: MethodChannel.Result) {
        val styleData = PlugPagStyleData(
            headTextColor = Util.callColorInt(call, "headTextColor", 0xFF000000.toInt()),
            headBackgroundColor = Util.callColorInt(call, "headBackgroundColor", 0xFFE13C70.toInt()),
            contentTextColor = Util.callColorInt(call, "contentTextColor", 0xFFDFDFE0.toInt()),
            contentTextValue1Color = Util.callColorInt(call, "contentTextValue1Color", 0xFFFFE000.toInt()),
            contentTextValue2Color = Util.callColorInt(call, "contentTextValue2Color", 0xFF000000.toInt()),
            positiveButtonTextColor = Util.callColorInt(call, "positiveButtonTextColor", 0xFFFFFFFF.toInt()),
            positiveButtonBackground = Util.callColorInt(call, "positiveButtonBackground", 0xFFFF358C.toInt()),
            negativeButtonTextColor = Util.callColorInt(call, "negativeButtonTextColor", 0xFF777778.toInt()),
            negativeButtonBackground = Util.callColorInt(call, "negativeButtonBackground", 0xFF000000.toInt()),
            genericButtonBackground = Util.callColorInt(call, "genericButtonBackground", 0xFF000000.toInt()),
            genericButtonTextColor = Util.callColorInt(call, "genericButtonTextColor", 0xFFFF358C.toInt()),
            genericSmsEditTextBackground = Util.callColorInt(call, "genericSmsEditTextBackground", 0xFF000000.toInt()),
            genericSmsEditTextTextColor = Util.callColorInt(call, "genericSmsEditTextTextColor", 0xFFFF358C.toInt()),
            lineColor = Util.callColorInt(call, "lineColor", 0xFF000000.toInt())
        )

        CoroutineHelper.launchIO(scope) {
            try {
                val applied = plugPag.setStyleData(styleData)

                CoroutineHelper.launchMain(scope) {
                    if (applied) {
                        logger.info("setStyleData", "Estilo de Janelas Configurado!")
                        result.success(
                            mapOf(
                                "success" to true,
                                "message" to "Estilo de Janelas Configurado!",
                                "data" to true
                            )
                        )
                    } else {
                        logger.error("setStyleData", "Falha ao Configurar Estilo de Janelas!")
                        result.success(
                            mapOf(
                                "success" to false,
                                "message" to "Falha ao Configurar Estilo de Janelas!",
                                "data" to false
                            )
                        )
                    }
                }
            } catch (e: PlugPagException) {
                CoroutineHelper.launchMain(scope) {
                    logger.error("setStyleData (PlugPagException)", "Erro ao Configurar Estilo de Janelas: ${e.message}")
                    result.success(mapOf(
                        "success" to false,
                        "message" to "Erro ao Configurar Estilo de Janelas!",
                        "data" to null
                    ))
                }
            }
        }
    }

    /** Define Estilo Visual (Cores) de Janelas PagSeguro de forma Assíncrona **/
    fun asyncSetStyles(call: MethodCall, result: MethodChannel.Result) {
        val styleData = PlugPagStyleData(
            headTextColor = Util.callColorInt(call, "headTextColor", 0xFF000000.toInt()),
            headBackgroundColor = Util.callColorInt(call, "headBackgroundColor", 0xFFE13C70.toInt()),
            contentTextColor = Util.callColorInt(call, "contentTextColor", 0xFFDFDFE0.toInt()),
            contentTextValue1Color = Util.callColorInt(call, "contentTextValue1Color", 0xFFFFE000.toInt()),
            contentTextValue2Color = Util.callColorInt(call, "contentTextValue2Color", 0xFF000000.toInt()),
            positiveButtonTextColor = Util.callColorInt(call, "positiveButtonTextColor", 0xFFFFFFFF.toInt()),
            positiveButtonBackground = Util.callColorInt(call, "positiveButtonBackground", 0xFFFF358C.toInt()),
            negativeButtonTextColor = Util.callColorInt(call, "negativeButtonTextColor", 0xFF777778.toInt()),
            negativeButtonBackground = Util.callColorInt(call, "negativeButtonBackground", 0xFF000000.toInt()),
            genericButtonBackground = Util.callColorInt(call, "genericButtonBackground", 0xFF000000.toInt()),
            genericButtonTextColor = Util.callColorInt(call, "genericButtonTextColor", 0xFFFF358C.toInt()),
            genericSmsEditTextBackground = Util.callColorInt(call, "genericSmsEditTextBackground", 0xFF000000.toInt()),
            genericSmsEditTextTextColor = Util.callColorInt(call, "genericSmsEditTextTextColor", 0xFFFF358C.toInt()),
            lineColor = Util.callColorInt(call, "lineColor", 0xFF000000.toInt())
        )

        CoroutineHelper.launchIO(scope) {
            try {
                plugPag.asyncSetStyles(
                    styleData = styleData,
                    isSetStylesListener = object : PlugPagSetStylesListener {

                        override fun onSetStylesFinished(setStylesResult: Boolean) {
                            CoroutineHelper.launchMain(scope) {
                                if (setStylesResult) {
                                    logger.info("asyncSetStyles (onSetStylesFinished)", "Estilo de Janelas Configurado!")
                                    result.success(
                                        mapOf(
                                            "success" to true,
                                            "message" to "Estilo de Janelas Configurado!",
                                            "data" to true
                                        )
                                    )
                                } else {
                                    logger.error("asyncSetStyles (onSetStylesFinished)", "Falha ao Configurar Estilo de Janelas!")
                                    result.success(
                                        mapOf(
                                            "success" to false,
                                            "message" to "Falha ao Configurar Estilo de Janelas!",
                                            "data" to false
                                        )
                                    )
                                }
                                plugPag.disposeSubscriber()
                            }
                        }

                        override fun onError(errorMessage: String) {
                            CoroutineHelper.launchMain(scope) {
                                logger.error("asyncSetStyles (onError)", "Erro ao Configurar Estilo de Janelas: $errorMessage")
                                result.success(
                                    mapOf(
                                        "success" to false,
                                        "message" to errorMessage,
                                        "data" to null
                                    )
                                )
                                plugPag.disposeSubscriber()
                            }
                        }
                    }
                )
            } catch (e: PlugPagException) {
                CoroutineHelper.launchMain(scope) {
                    logger.error("asyncSetStyles (PlugPagException)", "Erro ao Configurar Estilo de Janelas: ${e.message}")
                    result.success(
                        mapOf(
                            "success" to false,
                            "message" to "Erro ao Configurar Estilo de Janelas!",
                            "data" to null
                        )
                    )
                    plugPag.disposeSubscriber()
                }
            }
        }
    }
}

/** Extensão para converter PlugPagUserDataResult em Map<String, Any?> para envio ao Flutter **/
fun PlugPagUserDataResult.toMap(): Map<String, Any?> {
    return mapOf(
        "userNickName" to userNickName,
        "email" to email,
        "cnpjCpf" to cnpjCpf,
        "companyName" to companyName,
        "address" to address,
        "city" to city,
        "addressState" to addressState,
        "addressComplement" to addressComplement
    )
}