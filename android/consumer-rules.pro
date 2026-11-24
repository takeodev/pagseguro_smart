# Regras R8/ProGuard aplicadas automaticamente aos Apps que usam o pacote (build release com minificacao).

# O Wrapper do PagBank referencia a anotacao Parcelize, que so existe em tempo de compilacao (nao e necessaria na execucao).
-dontwarn kotlinx.android.parcel.Parcelize
-dontwarn kotlinx.parcelize.Parcelize

# Modelos do Wrapper trafegam entre processos (Parcelable) pelo servico do PagBank: nao renomear nem remover.
-keep class br.com.uol.pagseguro.plugpagservice.wrapper.** { *; }
