package com.takeodev.pagseguro_smart.utils

/** ======================================================================================
Arquivo         : VoidReceiptBridge.kt
Projeto         : PagSeguro Smart
Plataforma      : Android
Equipamentos    : Modelos de Maquininhas PagSeguro testados - P2 A7, P2 A11 & GPOS A11
Autor           : Fernando Takeo Miyaji
====================================================================================== **/

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.Message
import android.os.Messenger
import br.com.uol.pagseguro.plugpagservice.wrapper.PlugPag
import br.com.uol.pagseguro.plugpagservice.wrapper.serviceconnections.PaymentServiceConnection
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * Correção do recibo no ESTORNO (Wrapper PagSeguro 1.35.0, a última versão publicada).
 *
 * Problema: ao fim do estorno o serviço PagBank chama o `PlugPagPrintActionListener.onPrint` e fica esperando a
 * ação escolhida (doNothing / showPopup / doPrint / sendSMS). O Wrapper entrega essa ação por
 * `PlugPag.doPrintAction`, que envia a mensagem pela conexão guardada em `PlugPag.paymentConnection`.
 * Só o `doPayment` (e o `doAsyncPayment`) preenche essa conexão; o `voidPayment` e o `doAsyncVoidPayment` não.
 * Resultado: no estorno a ação é descartada em silêncio (conexão nula) ou vai por uma conexão velha de uma venda
 * anterior (às vezes funciona, às vezes não). O serviço espera 120 s, responde "PP1064 - Tempo limite expirado" e só
 * então devolve o estorno, que já estava aprovado.
 *
 * Correção: durante o estorno o plugin abre a sua própria ligação (bind) com o serviço PagBank e coloca em
 * `paymentConnection` uma conexão que encaminha a mensagem por essa ligação. Assim a ação do recibo chega na hora,
 * pelo próprio código do Wrapper. No fim do estorno a conexão anterior é devolvida e a ligação é desfeita.
 * Se a ligação falhar, nada muda em relação ao comportamento anterior (o Wrapper continua como antes).
 * A venda (doPayment) não usa esta classe.
 */
class VoidReceiptBridge(private val context: Context, private val plugPag: PlugPag) {

    companion object {
        /** Tag utilizada nos logs */
        private const val TAG = "VoidReceiptBridge"

        /** Mesmo serviço que o Wrapper usa (PlugPagServiceCommandBase.createServiceIntent) */
        private const val SERVICE_PACKAGE = "br.com.uol.pagseguro.plugpagservice"
        private const val SERVICE_CLASS = "br.com.uol.pagseguro.plugpagservice.payment.PlugPagService"

        /** Tempo máximo, em ms, esperando a ligação antes de seguir com o estorno (só no estorno síncrono) */
        private const val BIND_WAIT_MS = 3000L
    }

    private val logger = Logger(TAG)
    private val mainHandler = Handler(Looper.getMainLooper())

    /**
     * Conexão "falsa" do Wrapper: só repassa a mensagem do `doPrintAction` ao serviço, pelo [binder] da ligação aberta
     * pelo plugin. É o mesmo envio que o `BaseServiceConnection.send` do Wrapper faz.
     */
    private class ForwardingConnection(private val binder: IBinder) : PaymentServiceConnection(Message.obtain()) {
        override fun send(message: Message): Boolean = try {
            Messenger(binder).send(message)
            true
        } catch (e: Exception) {
            false
        }
    }

    /**
     * Uma ligação aberta para um estorno. As mudanças em `paymentConnection` são feitas sempre na Main Thread, a mesma
     * em que o Wrapper chama o `onPrint` (ele chega por BroadcastReceiver), então não há disputa entre threads.
     */
    inner class Session internal constructor() : ServiceConnection {
        private val connected = CountDownLatch(1)
        private var previous: PaymentServiceConnection? = null
        private var installed: ForwardingConnection? = null
        private var bound = false
        private var closed = false

        override fun onServiceConnected(name: ComponentName?, binder: IBinder?) {
            if (closed || binder == null) return
            previous = plugPag.paymentConnection
            installed = ForwardingConnection(binder).also { plugPag.paymentConnection = it }
            logger.info("onServiceConnected", "Conexão de recibo do estorno pronta")
            connected.countDown()
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            logger.warn("onServiceDisconnected", "Serviço PagBank desconectado durante o estorno")
        }

        /** Abre a ligação (na Main Thread). Devolve false se o Android recusar o bind. */
        internal fun bind(): Boolean = try {
            val intent = Intent().setComponent(ComponentName(SERVICE_PACKAGE, SERVICE_CLASS))
            bound = context.bindService(intent, this, Context.BIND_AUTO_CREATE)
            if (!bound) logger.warn("bind", "Serviço PagBank recusou a ligação; estorno segue sem a correção")
            bound
        } catch (e: Exception) {
            logger.error("bind (Exception)", "Erro ao ligar ao serviço PagBank: ${e.message}")
            false
        }

        /** Espera a ligação ficar pronta (nunca chamar na Main Thread: o aviso de pronto chega nela) */
        internal fun await(timeoutMs: Long): Boolean = connected.await(timeoutMs, TimeUnit.MILLISECONDS)

        /** Devolve a conexão anterior ao Wrapper e desfaz a ligação. Pode ser chamado de qualquer thread. */
        fun close() = runOnMain {
            if (closed) return@runOnMain
            closed = true
            if (installed != null && plugPag.paymentConnection === installed) plugPag.paymentConnection = previous
            installed = null
            previous = null
            if (bound) runCatching { context.unbindService(this) }
            bound = false
        }
    }

    /**
     * Abre a correção para um estorno. Chamado de uma thread de IO (estorno síncrono), espera até [BIND_WAIT_MS] a
     * ligação ficar pronta; chamado na Main Thread (estorno assíncrono), não espera: a ligação fica pronta em
     * milissegundos, muito antes do `onPrint`, que só chega depois do cartão e da autorização.
     * Sempre devolve uma [Session]; chame [Session.close] no fim do estorno (sucesso ou erro).
     */
    fun open(): Session {
        val session = Session()
        if (Looper.myLooper() == Looper.getMainLooper()) {
            session.bind()
        } else {
            val bindOk = CountDownLatch(1)
            var ok = false
            mainHandler.post { ok = session.bind(); bindOk.countDown() }
            bindOk.await(BIND_WAIT_MS, TimeUnit.MILLISECONDS)
            if (ok && !session.await(BIND_WAIT_MS)) logger.warn("open", "Ligação com o serviço PagBank demorou; estorno segue mesmo assim")
        }
        return session
    }

    /** Executa [block] na Main Thread (direto, se já estiver nela) */
    private fun runOnMain(block: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) block() else mainHandler.post(block)
    }
}
