package takeodev.pagseguro_smart.utils

/** ======================================================================================
Arquivo         : CoroutineHelper.kt
Projeto         : PagSeguro Smart
Plataforma      : Android
Equipamentos    : Modelos de Maquininhas PagSeguro testados - P2 A7, P2 A11 & GPOS A11
Autor           : Fernando Takeo Miyaji
====================================================================================== **/

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

/** Helpers para execução de corrotinas no plugin **/
object CoroutineHelper {
    /** Executa código no Main Thread **/
    fun launchMain(scope: CoroutineScope, block: suspend CoroutineScope.() -> Unit) {
        scope.launch(Dispatchers.Main, block = block)
    }

    /** Executa código em Background **/
    fun launchDefault(scope: CoroutineScope, block: suspend CoroutineScope.() -> Unit) {
        scope.launch(Dispatchers.Default, block = block)
    }

    /** Executa código em Thread de I/O (operações bloqueantes) **/
    fun launchIO(scope: CoroutineScope, block: suspend CoroutineScope.() -> Unit) {
        scope.launch(Dispatchers.IO, block = block)
    }
}
