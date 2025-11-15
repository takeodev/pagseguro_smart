package takeodev.pagseguro_smart.utils

/** ======================================================================================
Arquivo         : Logger.kt
Projeto         : PagSeguro Smart
Plataforma      : Android
Equipamentos    : Modelos de Maquininhas PagSeguro testados - P2 A7, P2 A11 & GPOS A11
Autor           : Fernando Takeo Miyaji
====================================================================================== **/

import android.util.Log
import android.text.format.DateFormat

/**
 * Logger personalizado para o plugin PagSeguro Smart
 * @param tag TAG para identificar a origem do log
 */
class Logger(private val tag: String) {

    private fun formatMessage(step: String, message: String): String {
        val timestamp = DateFormat.format("yyyy-MM-dd HH:mm:ss", java.util.Date())
        val threadName = Thread.currentThread().name
        return "[$timestamp][$threadName] $step | $message"
    }

    fun info(step: String, message: String) {
        Log.i(tag, formatMessage(step, message))
    }

    fun debug(step: String, message: String) {
        Log.d(tag, formatMessage(step, message))
    }

    fun warn(step: String, message: String) {
        Log.w(tag, formatMessage(step, message))
    }

    fun error(step: String, message: String) {
        Log.e(tag, formatMessage(step, message))
    }
}