import 'package:flutter/material.dart';

/// Modelo de Dados de Layout e Estilo de Janelas PagSeguro (PlugPagStyleData)
/// Documentação: https://pagseguro.github.io/pagseguro-sdk-plugpagservicewrapper/-wrapper-p-p-s/br.com.uol.pagseguro.plugpagservice.wrapper/-plug-pag-style-data/index.html
class StyleDataModel {
  final Color headTextColor;
  final Color headBackgroundColor;
  final Color contentTextColor;
  final Color contentTextValue1Color;
  final Color contentTextValue2Color;
  final Color positiveButtonTextColor;
  final Color positiveButtonBackground;
  final Color negativeButtonTextColor;
  final Color negativeButtonBackground;
  final Color genericButtonBackground;
  final Color genericButtonTextColor;
  final Color genericSmsEditTextBackground;
  final Color genericSmsEditTextTextColor;
  final Color lineColor;

  const StyleDataModel({
    required this.headTextColor,
    required this.headBackgroundColor,
    required this.contentTextColor,
    required this.contentTextValue1Color,
    required this.contentTextValue2Color,
    required this.positiveButtonTextColor,
    required this.positiveButtonBackground,
    required this.negativeButtonTextColor,
    required this.negativeButtonBackground,
    required this.genericButtonBackground,
    required this.genericButtonTextColor,
    required this.genericSmsEditTextBackground,
    required this.genericSmsEditTextTextColor,
    required this.lineColor,
  });
}
