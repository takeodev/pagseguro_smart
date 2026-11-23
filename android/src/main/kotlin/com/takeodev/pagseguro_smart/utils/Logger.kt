package com.takeodev.pagseguro_smart.utils

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
 * Logger personalizado para o plugin PagSeguro Smart.
 * Formato da linha: `[data hora][thread] step | message`, onde `step` é o nome da operação.
 * Atenção LGPD: não registre dados pessoais ou de cartão na mensagem.
 * @param tag TAG para identificar a origem do log
 */
class Logger(private val tag: String) {

    companion object {
        /**
         * Liga/desliga os logs informativos (info, debug, warn) de todo o plugin. Padrão: ligado.
         * Erros (error) são sempre registrados. Alterado pelo Dart em `setLogEnabled` (útil em produção).
         **/
        @Volatile var enabled: Boolean = true
    }

    private fun formatMessage(step: String, message: String): String {
        val timestamp = DateFormat.format("yyyy-MM-dd HH:mm:ss", java.util.Date())
        val threadName = Thread.currentThread().name
        return "[$timestamp][$threadName] $step | $message"
    }

    fun info(step: String, message: String) {
        if (enabled) Log.i(tag, formatMessage(step, message))
    }

    fun debug(step: String, message: String) {
        if (enabled) Log.d(tag, formatMessage(step, message))
    }

    fun warn(step: String, message: String) {
        if (enabled) Log.w(tag, formatMessage(step, message))
    }

    fun error(step: String, message: String) {
        Log.e(tag, formatMessage(step, message))
    }
}