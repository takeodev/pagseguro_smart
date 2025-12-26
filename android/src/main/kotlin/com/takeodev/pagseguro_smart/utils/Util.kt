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
     *
     * @param call MethodCall recebido do Flutter
     * @param key Nome da chave do argumento
     * @param defaultValue Valor padrão caso a chave não exista ou seja nula
     * @return String válida
     */
    fun callString(call: MethodCall, key: String, defaultValue: String): String {
        return call.argument<String>(key) ?: defaultValue
    }

    /**
     * Recupera um argumento numérico do MethodCall como Int.
     *
     * @param call MethodCall recebido do Flutter
     * @param key Nome da chave do argumento
     * @param defaultValue Valor padrão caso a chave não exista ou seja nula
     * @return Int válido
     */
    fun callInt(call: MethodCall, key: String, defaultValue: Int): Int {
        return call.argument<Number>(key)?.toInt() ?: defaultValue
    }

    /**
     * Recupera um argumento de cor vindo do Flutter e converte para
     * um HEX válido aceito pelo Android (`#AARRGGBB`).
     *
     * Aceita:
     * - Int (ex: Color.value do Flutter)
     * - Long
     * - String no formato `#RRGGBB` ou `#AARRGGBB`
     *
     * Caso o valor seja inválido, retorna o default informado.
     *
     * @param call MethodCall recebido do Flutter
     * @param key Nome da chave do argumento
     * @param defaultValue Cor padrão no formato HEX (`#AARRGGBB`)
     * @return String HEX válida e opaca
     */
    fun callHex(call: MethodCall, key: String, defaultValue: String): String {
        val value = call.argument<Any>(key)

        return when (value) {
            is Int -> String.format("#%08X", value)
            is Long -> String.format("#%08X", value.toInt())
            is String -> {
                val hex = value.uppercase()
                if (hex.startsWith("#") && (hex.length == 7 || hex.length == 9)) {
                    forceOpaque(hex)
                } else {
                    defaultValue
                }
            }
            else -> defaultValue
        }
    }

    /**
     * Recupera um valor de cor a partir de um [MethodCall] do Flutter
     * e converte de forma segura para um [Int] no formato ARGB.
     *
     * Este método deve ser utilizado em APIs do PlugPag que exigem cores
     * como valores inteiros, como o [PlugPagStyleData].
     *
     * Formatos de entrada suportados vindos do Flutter:
     * - [Int]    → Utilizado diretamente (recomendado ao passar Color.value)
     * - [Long]   → Convertido para [Int]
     * - [String] → Interpretado como cor HEX (#RRGGBB ou #AARRGGBB)
     *
     * Caso o valor informado seja inválido, inexistente ou não possa ser
     * convertido corretamente, o [defaultValue] será retornado para evitar
     * falhas em tempo de execução.
     *
     * @param call MethodCall recebido do Flutter
     * @param key Nome da chave do argumento
     * @param defaultValue Cor ARGB padrão utilizada como fallback
     *
     * @return Cor válida no formato ARGB como [Int]
     */
    fun callColorInt(call: MethodCall, key: String, defaultValue: Int): Int {
        val value = call.argument<Any>(key)

        return when (value) {
            is Int -> value
            is Long -> value.toInt()
            is String -> {
                try {
                    android.graphics.Color.parseColor(forceOpaque(value))
                } catch (e: IllegalArgumentException) {
                    defaultValue
                }
            }
            else -> defaultValue
        }
    }


    /**
     * Garante que uma cor HEX esteja no formato opaco.
     *
     * Se receber `#RRGGBB`, converte para `#FFRRGGBB`.
     * Se já estiver em `#AARRGGBB`, retorna sem alteração.
     *
     * @param hex String HEX de cor
     * @return String HEX com alpha forçado para `FF`
     */
    fun forceOpaque(hex: String): String {
        return if (hex.length == 7) {
            "#FF" + hex.substring(1)
        } else {
            hex
        }
    }
}