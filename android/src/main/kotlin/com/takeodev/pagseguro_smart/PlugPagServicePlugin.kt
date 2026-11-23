package com.takeodev.pagseguro_smart

/** ======================================================================================
Arquivo         : PlugPagServicePlugin.kt
Projeto         : PagSeguro Smart
Plataforma      : Android
Equipamentos    : Modelos de Maquininhas PagSeguro testados - P2 A7, P2 A11 & GPOS A11
Autor           : Fernando Takeo Miyaji
====================================================================================== **/

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.CoroutineExceptionHandler
import kotlinx.coroutines.SupervisorJob
import android.util.Log
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPag
import com.takeodev.pagseguro_smart.manager.PinPadManager
import com.takeodev.pagseguro_smart.manager.PaymentManager
import com.takeodev.pagseguro_smart.manager.ReceiptManager
import com.takeodev.pagseguro_smart.manager.DeviceManager
import com.takeodev.pagseguro_smart.utils.Logger

/**
 * Classe principal do plugin PagSeguro Smart para Flutter.
 * Implementa FlutterPlugin e MethodCallHandler.
 *
 * Recebe as chamadas do canal `plugpag_channel` (enviadas pelo PagSeguroService em Dart) e
 * repassa cada uma ao Manager responsável (PinPad, Pagamento, Recibo ou Dispositivo).
 * O PlugPag é criado uma única vez e reaproveitado em todos os Managers.
*/
class PlugPagServicePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    companion object {
        /** Tag utilizada nos logs */
        private const val TAG = "PlugPagServicePlugin"
    }

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var plugPag: PlugPag
    /** SupervisorJob: a falha de uma tarefa não cancela as demais (ex.: pagamento em andamento) */
    private val pluginJob = SupervisorJob()
    private val pluginScope = CoroutineScope(
        Dispatchers.Default + pluginJob + CoroutineExceptionHandler { _, throwable ->
            Log.e(TAG, "Erro não tratado em corrotina: ${throwable.message}", throwable)
        }
    )

    // Instâncias dos managers
    private lateinit var pinPadManager: PinPadManager
    private lateinit var paymentManager: PaymentManager
    private lateinit var receiptManager: ReceiptManager
    private lateinit var deviceManager: DeviceManager

    /** Inicialização do Plugin */
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "plugpag_channel")
        channel.setMethodCallHandler(this)

        // Cria o PlugPag só na primeira vez: ele é o mesmo objeto usado por todos os Managers
        if (!::plugPag.isInitialized) plugPag = PlugPag(context)

        // Inicializa gerenciadores
        pinPadManager = PinPadManager(plugPag, pluginScope)
        receiptManager = ReceiptManager(plugPag, pluginScope)
        // O PaymentManager recebe o canal para enviar eventos ao Dart (ex.: onPaymentProgress)
        paymentManager = PaymentManager(plugPag, pluginScope, receiptManager, channel)
        deviceManager = DeviceManager(plugPag, pluginScope)
    }

    /**
     * Recebe chamadas do Dart e redireciona.
     * Nome do método no Dart = nome do `when` abaixo. Nome desconhecido responde `notImplemented`
     * (o Dart recebe `MissingPluginException`, tratado pelo `_invokeNative` como falha).
     */
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            // Métodos Síncronos: respondem uma vez, com o resultado final da operação
            "isAuthenticated" -> pinPadManager.isAuthenticated(result)
            "initPinPad" -> pinPadManager.initPinPad(call, result)
            "getUserData" -> pinPadManager.getUserData(result)
            "getSerialNumber" -> pinPadManager.getSerialNumber(result)
            "rebootDevice" -> pinPadManager.rebootDevice(result)
            "isServiceBusy" -> pinPadManager.isServiceBusy(result)
            "setStyleData" -> pinPadManager.setStyleData(call, result)
            "doPayment" -> paymentManager.doPayment(call, result)
            "abortTransaction" -> paymentManager.abortTransaction(result)
            "voidPayment" -> paymentManager.voidPayment(call, result)
            "getLastTransaction" -> paymentManager.getLastTransaction(result)
            "reprintCustomerReceipt" -> receiptManager.reprintCustomerReceipt(result)
            "reprintEstablishmentReceipt" -> receiptManager.reprintEstablishmentReceipt(result)
            "sendReceiptSMS" -> receiptManager.sendReceiptSMS(call, result)
            "setPrintActionListener" -> receiptManager.setPrintActionListener(call, result)
            "setPlugPagCustomPrinterLayout" -> receiptManager.setPlugPagCustomPrinterLayout(call, result)

            // Métodos Assíncronos: usam listeners do Wrapper; a resposta sai quando o evento termina
            "asyncIsAuthenticated" -> pinPadManager.asyncIsAuthenticated(result)
            "asyncInitPinPad" -> pinPadManager.asyncInitPinPad(call, result)
            "asyncSetStyles" -> pinPadManager.asyncSetStyles(call, result)
            "doAsyncPayment" -> paymentManager.doAsyncPayment(call, result)
            "asyncAbortTransaction" -> paymentManager.asyncAbortTransaction(result)
            "asyncVoidPayment" -> paymentManager.asyncVoidPayment(call, result)
            "asyncGetLastTransaction" -> paymentManager.asyncGetLastTransaction(result)
            "asyncReprintCustomerReceipt" -> receiptManager.asyncReprintCustomerReceipt(result)
            "asyncReprintEstablishmentReceipt" -> receiptManager.asyncReprintEstablishmentReceipt(result)

            // Dispositivo, Parcelamento, Impressão, Ativação e Subadquirente (1.4.0)
            "getModel" -> deviceManager.getModel(result)
            "hasCapability" -> deviceManager.hasCapability(call, result)
            "hasSoftwareCapability" -> deviceManager.hasSoftwareCapability(call, result)
            "checkPermission" -> deviceManager.checkPermission(result)
            "beep" -> deviceManager.beep(call, result)
            "setLed" -> deviceManager.setLed(call, result)
            "updateRemoteConfig" -> deviceManager.updateRemoteConfig(result)
            "startOnBoarding" -> deviceManager.startOnBoarding(result)
            "getCardData" -> deviceManager.getCardData(result)
            "deactivate" -> deviceManager.deactivate(call, result)
            "asyncDeactivate" -> deviceManager.asyncDeactivate(call, result)
            "invalidateAuthentication" -> deviceManager.invalidateAuthentication(result)
            "initPagBankActivation" -> deviceManager.initPagBankActivation(result)
            "calculateInstallments" -> deviceManager.calculateInstallments(call, result)
            "asyncCalculateInstallments" -> deviceManager.asyncCalculateInstallments(call, result)
            "printFromFile" -> deviceManager.printFromFile(call, result)
            "hasSubAcquirer" -> deviceManager.hasSubAcquirer(result)
            "getSubAcquirerData" -> deviceManager.getSubAcquirerData(result)
            "initializeSubAcquirer" -> deviceManager.initializeSubAcquirer(call, result)
            "invalidateSubAcquirer" -> deviceManager.invalidateSubAcquirer(result)
            "setSellDeeplink" -> deviceManager.setSellDeeplink(call, result)
            "removeSellDeeplink" -> deviceManager.removeSellDeeplink(result)

            // Liga/desliga os logs informativos do plugin (erros continuam sendo registrados)
            "setLogEnabled" -> {
                Logger.enabled = call.argument<Boolean>("enabled") ?: true
                result.success(mapOf("success" to true, "message" to if (Logger.enabled) "Logs Ligados!" else "Logs Desligados!", "data" to Logger.enabled))
            }

            else -> result.notImplemented()
        }
    }

    /** Desanexa plugin */
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        pluginJob.cancel()
    }
}
