package com.takeodev.pagseguro_smart.utils

/** ======================================================================================
Arquivo         : Util.kt
Projeto         : PagSeguro Smart
Plataforma      : Android
Equipamentos    : Modelos de Maquininhas PagSeguro testados - P2 A7, P2 A11 & GPOS A11
Autor           : Fernando Takeo Miyaji
====================================================================================== **/

import io.flutter.plugin.common.MethodCall

/**
 * Utilitários para leitura segura de argumentos vindos do Flutter
 */
object Util {
    /**
     * Recupera um argumento do tipo String a partir do MethodCall.
     */
    fun callString(call: MethodCall, key: String): String? {
        return call.argument<String>(key)
    }

    /**
     * Recupera um argumento numérico do MethodCall como Int.
     */
    fun callInt(call: MethodCall, key: String, default: Int): Int {
        return call.argument<Number>(key)?.toInt() ?: default
    }

    /**
     * Recupera um argumento de cor vindo do Flutter e converte para
     * um HEX válido aceito pelo Android (`#AARRGGBB`).
     * Retorna null se o argumento não existir ou for inválido.
     */
    fun callHex(call: MethodCall, key: String): String? {
        val value = call.argument<Any>(key) ?: return null

        return when (value) {
            is Int -> String.format("#%08X", value)
            is Long -> String.format("#%08X", value.toInt())
            is String -> {
                val hex = value.uppercase()
                // Aceita formatos com # ou sem prefixo, com 6 ou 8 caracteres hex
                if (hex.startsWith("#")) {
                    if (hex.length == 7 || hex.length == 9) forceOpaque(hex) else null
                } else {
                    // Caso venha sem o #, tenta tratar
                    if (hex.length == 6 || hex.length == 8) forceOpaque("#$hex") else null
                }
            }
            else -> null
        }
    }

    /**
     * Recupera um valor de cor a partir de um [MethodCall] do Flutter
     * e converte para [Int] ARGB. Retorna null se falhar.
     */
    fun callColorInt(call: MethodCall, key: String): Int? {
        val value = call.argument<Any>(key) ?: return null

        return when (value) {
            is Int -> value
            is Long -> value.toInt()
            is String -> {
                try {
                    android.graphics.Color.parseColor(forceOpaque(value))
                } catch (e: Exception) {
                    null
                }
            }
            else -> null
        }
    }

    /**
     * Garante que uma cor HEX esteja no formato opaco.
     */
    fun forceOpaque(hex: String): String {
        return when (hex.length) {
            7 -> "#FF" + hex.substring(1) // #RRGGBB -> #FFRRGGBB
            9 -> hex                      // #AARRGGBB -> mantém
            else -> hex
        }
    }
}