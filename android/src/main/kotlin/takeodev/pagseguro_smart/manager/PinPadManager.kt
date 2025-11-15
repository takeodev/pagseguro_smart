package takeodev.pagseguro_smart.manager

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
import takeodev.pagseguro_smart.utils.Logger
import takeodev.pagseguro_smart.utils.CoroutineHelper

/** Gerencia a ativação do PinPad **/
class PinPadManager(private val plugPag: PlugPag, private val scope: CoroutineScope) {

    companion object {
        /** Tag utilizada nos logs */
        private const val TAG = "PinPadManager"
    }

    private val logger = Logger(TAG)

    /** Verifica se PinPad foi Autenticado **/
    fun isAuthenticated(result: MethodChannel.Result) {
        try {
            plugPag.asyncIsAuthenticated(
                object : PlugPagIsActivatedListener {
                    override fun onIsActivated(isActivated: Boolean) {
                        CoroutineHelper.launchMain(scope) {
                            if (isActivated) {
                                logger.info("isAuthenticated (onIsActivated, isActivated == true)", "PinPad Autenticado")
                                result.success(mapOf(
                                    "success" to true,
                                    "message" to "PinPad Autenticado!",
                                    "data" to null
                                ))
                            } else {
                                logger.info("isAuthenticated (onIsActivated, isActivated == false)", "PinPad Não Autenticado")
                                result.success(mapOf(
                                    "success" to false,
                                    "message" to "PinPad Não Autenticado!",
                                    "data" to null
                                ))
                            }
                        }
                    }

                    override fun onError(errorMessage: String) {
                        CoroutineHelper.launchMain(scope) {
                            logger.error("isAuthenticated (onError)", "Erro na Autenticação: $errorMessage")
                            result.success(mapOf(
                                "success" to false,
                                "message" to "$errorMessage",
                                "data" to null
                            ))
                        }
                    }
                }
            )
        } catch (e: Exception) {
            CoroutineHelper.launchMain(scope) {
                logger.error("isAuthenticated (Exception)", "Erro ao Autenticar PinPad: ${e.message}")
                result.success(mapOf(
                    "success" to false,
                    "message" to "Erro Fatal ao Autenticar PinPad!",
                    "data" to null
                ))
            }
        }
    }

    /** Inicializa e ativa o PinPad **/
    fun initPinPad(call: MethodCall, result: MethodChannel.Result) {
        try {
            val code = call.argument<String>("activationCode").orEmpty()

            if (code.isEmpty()) {
                logger.warn("initPinPad (code.isEmpty())", "Fornecer Código de Ativação")
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
                            logger.info("initPinPad (onActivationProgress)", "Ativando PinPad | Id: ${eventData.eventCode} | ${eventData.customMessage}")
                        }
                    }

                    override fun onSuccess(initializationResult: PlugPagInitializationResult) {
                        CoroutineHelper.launchMain(scope) {
                            logger.info("initPinPad (onSuccess)", "PinPad Ativado")
                            result.success(mapOf(
                                "success" to true,
                                "message" to "PinPad Ativado com Sucesso!",
                                "data" to null
                            ))
                        }
                    }

                    override fun onError(initializationResult: PlugPagInitializationResult) {
                        CoroutineHelper.launchMain(scope) {
                            logger.error("initPinPad (onError)", "Erro na Ativação | Id: ${initializationResult.errorCode}")
                            result.success(mapOf(
                                "success" to false,
                                "message" to "${initializationResult.errorMessage} (${initializationResult.errorCode})",
                                "data" to null
                            ))
                        }
                    }
                }
            )
        } catch (e: Exception) {
            CoroutineHelper.launchMain(scope) {
                logger.error("initPinPad (Exception)", "Erro ao Ativar PinPad: ${e.message}")
                result.success(mapOf(
                    "success" to false,
                    "message" to "Erro Fatal ao Ativar PinPad!",
                    "data" to null
                ))
            }
        }
    }

    /** Coleta Dados do Usuário (Dono da Maquininha) **/
    fun getUserData(result: MethodChannel.Result) {
        try {
            CoroutineHelper.launchIO(scope) { // roda em thread de background
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
            }
        } catch (e: Exception) {
            CoroutineHelper.launchMain(scope) {
                logger.error("getUserData (Exception)", "Erro ao Obter Dados do Usuário: ${e.message}")
                result.success(
                    mapOf(
                        "success" to false,
                        "message" to "Erro Fatal ao Obter Dados do Usuário!",
                        "data" to null
                    )
                )
            }
        }
    }

    /** Busca o Número de Série da Maquininha **/
    fun getSerialNumber(result: MethodChannel.Result) {
        try {
            CoroutineHelper.launchIO(scope) { // roda em thread de background
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
            }
        } catch (e: Exception) {
            CoroutineHelper.launchMain(scope) {
                logger.error("getSerialNumber (Exception)", "Erro ao Obter Número de Série: ${e.message}")
                result.success(
                    mapOf(
                        "success" to false,
                        "message" to "Erro Fatal ao Obter Número de Série!",
                        "data" to null
                    )
                )
            }
        }
    }

    /** Reinicia a Maquininha **/
    fun rebootDevice(result: MethodChannel.Result) {
        try {
            CoroutineHelper.launchIO(scope) { // roda em thread de background
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
            }
        } catch (e: PlugPagException) {
            CoroutineHelper.launchMain(scope) {
                logger.error("rebootDevice (PlugPagException)", "Erro ao Reiniciar Maquininha: ${e.message}")
                result.success(
                    mapOf(
                        "success" to false,
                        "message" to "Erro Fatal ao Reiniciar Maquininha!",
                        "data" to null
                    )
                )
            }
        }
    }

    /** Verifica se o Serviço da PagSeguro está Livre **/
    fun isServiceNotBusy(result: MethodChannel.Result) {
        try {
            CoroutineHelper.launchIO(scope) { // roda em thread de background
                val isBusy = plugPag.isServiceBusy()

                CoroutineHelper.launchMain(scope) {
                    if (isBusy == true) {
                        logger.info("isServiceBusy (isBusy == true)", "Serviço da PagSeguro Ocupado")
                        result.success(
                            mapOf(
                                "success" to false,
                                "message" to "Serviço da PagSeguro Ocupado!",
                                "data" to null
                            )
                        )
                    } else if (isBusy == false) {
                        logger.info("isServiceBusy (isBusy == false)", "Serviço da PagSeguro Livre")
                        result.success(
                            mapOf(
                                "success" to true,
                                "message" to "Serviço da PagSeguro Livre!",
                                "data" to null
                            )
                        )
                    } else {
                        logger.error("isServiceBusy (isBusy == null)", "Falha ao Verificar Serviço da PagSeguro")
                        result.success(
                            mapOf(
                                "success" to false,
                                "message" to "Falha ao Verificar Serviço da PagSeguro.",
                                "data" to null
                            )
                        )
                    }
                }
            }
        } catch (e: PlugPagException) {
            CoroutineHelper.launchMain(scope) {
                logger.error("isServiceBusy (PlugPagException)", "Erro ao Verificar Serviço da PagSeguro: ${e.message}")
                result.success(
                    mapOf(
                        "success" to false,
                        "message" to "Erro Fatal ao Verificar Serviço da PagSeguro!",
                        "data" to null
                    )
                )
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