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
import kotlinx.coroutines.Job
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPag
import com.takeodev.pagseguro_smart.manager.PinPadManager
import com.takeodev.pagseguro_smart.manager.PaymentManager
import com.takeodev.pagseguro_smart.manager.ReceiptManager

/**
 * Classe principal do plugin PagSeguro Smart para Flutter.
 * Implementa FlutterPlugin e MethodCallHandler.
*/
class PlugPagServicePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    companion object {
        /** Tag utilizada nos logs */
        private const val TAG = "PlugPagServicePlugin"
    }

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var plugPag: PlugPag
    private val pluginJob = Job()
    private val pluginScope = CoroutineScope(Dispatchers.Default + pluginJob)

    // Instâncias dos managers
    private lateinit var pinPadManager: PinPadManager
    private lateinit var paymentManager: PaymentManager
    private lateinit var receiptManager: ReceiptManager

    /** Inicialização do Plugin */
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "plugpag_channel")
        channel.setMethodCallHandler(this)

        if (!::plugPag.isInitialized) plugPag = PlugPag(context)

        // Inicializa gerenciadores
        pinPadManager = PinPadManager(plugPag, pluginScope)
        receiptManager = ReceiptManager(plugPag, pluginScope)
        paymentManager = PaymentManager(plugPag, pluginScope, receiptManager)

        // Define canal global
        PaymentManager.plugPagChannel = channel
    }

    /** Recebe chamadas do Dart e redireciona */
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            // Métodos Síncronos
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

            // Métodos Assíncronos
            "asyncIsAuthenticated" -> pinPadManager.asyncIsAuthenticated(result)
            "asyncInitPinPad" -> pinPadManager.asyncInitPinPad(call, result)
            "asyncSetStyles" -> pinPadManager.asyncSetStyles(call, result)
            "doAsyncPayment" -> paymentManager.doAsyncPayment(call, result)
            "asyncAbortTransaction" -> paymentManager.asyncAbortTransaction(result)
            "asyncVoidPayment" -> paymentManager.asyncVoidPayment(call, result)
            "asyncGetLastTransaction" -> paymentManager.asyncGetLastTransaction(result)
            "asyncReprintCustomerReceipt" -> receiptManager.asyncReprintCustomerReceipt(result)
            "asyncReprintEstablishmentReceipt" -> receiptManager.asyncReprintEstablishmentReceipt(result)

            else -> result.notImplemented()
        }
    }

    /** Desanexa plugin */
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        pluginJob.cancel()
    }
}
