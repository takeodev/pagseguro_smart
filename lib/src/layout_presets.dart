import 'package:flutter/material.dart';

enum LayoutPreset {
  pagseguroDefault,
  darkBlue,
  darkGreen,
  lightCustom,
}

class LayoutPresets {
  static Map<LayoutPreset, Map<String, Color>> presets = {
    /// Padrão de Exemplo PagSeguro Wrapper
    // https://pagseguro.github.io/pagseguro-sdk-plugpagservicewrapper/-wrapper-p-p-s/br.com.uol.pagseguro.plugpagservice.wrapper/-plug-pag/set-style-data.html
    LayoutPreset.pagseguroDefault: {
      'headTextColor': Colors.black,
      'headBackgroundColor': const Color(0xFFE13C70),
      'contentTextColor': const Color(0xFFDFDFE0),
      'contentTextValue1Color': const Color(0xFFFFE000),
      'contentTextValue2Color': Colors.black,
      'positiveButtonTextColor': Colors.black,
      'positiveButtonBackground': const Color(0xFFFF358C),
      'negativeButtonTextColor': const Color(0xFF777778),
      'negativeButtonBackground': Colors.black,
      'genericButtonBackground': Colors.black,
      'genericButtonTextColor': const Color(0xFFFF358C),
      'genericSmsEditTextBackground': Colors.black,
      'genericSmsEditTextTextColor': const Color(0xFFFF358C),
      'lineColor': Colors.black,
    },

    /// 🔵 Dark Blue
    LayoutPreset.darkBlue: {
      'headTextColor': Colors.white,
      'headBackgroundColor': const Color(0xFF0D1B2A),
      'contentTextColor': const Color(0xFFE0E1DD),
      'contentTextValue1Color': const Color(0xFF4CC9F0),
      'contentTextValue2Color': Colors.white,
      'positiveButtonTextColor': Colors.white,
      'positiveButtonBackground': const Color(0xFF4CC9F0),
      'negativeButtonTextColor': Colors.white70,
      'negativeButtonBackground': const Color(0xFF415A77),
      'genericButtonBackground': const Color(0xFF1B263B),
      'genericButtonTextColor': const Color(0xFF4CC9F0),
      'genericSmsEditTextBackground': const Color(0xFF1B263B),
      'genericSmsEditTextTextColor': Colors.white,
      'lineColor': const Color(0xFF778DA9),
    },

    /// 🟢 Dark Green
    LayoutPreset.darkGreen: {
      'headTextColor': Colors.white,
      'headBackgroundColor': const Color(0xFF1B4332),
      'contentTextColor': const Color(0xFFD8F3DC),
      'contentTextValue1Color': const Color(0xFF52B788),
      'contentTextValue2Color': Colors.white,
      'positiveButtonTextColor': Colors.white,
      'positiveButtonBackground': const Color(0xFF52B788),
      'negativeButtonTextColor': Colors.white70,
      'negativeButtonBackground': const Color(0xFF2D6A4F),
      'genericButtonBackground': const Color(0xFF081C15),
      'genericButtonTextColor': const Color(0xFF52B788),
      'genericSmsEditTextBackground': const Color(0xFF081C15),
      'genericSmsEditTextTextColor': Colors.white,
      'lineColor': const Color(0xFF95D5B2),
    },

    /// ☀️ Light Custom
    LayoutPreset.lightCustom: {
      'headTextColor': Colors.black,
      'headBackgroundColor': const Color(0xFFF1FAEE),
      'contentTextColor': const Color(0xFF1D3557),
      'contentTextValue1Color': const Color(0xFFE63946),
      'contentTextValue2Color': Colors.black,
      'positiveButtonTextColor': Colors.white,
      'positiveButtonBackground': const Color(0xFFE63946),
      'negativeButtonTextColor': Colors.black54,
      'negativeButtonBackground': const Color(0xFFA8DADC),
      'genericButtonBackground': const Color(0xFFF1FAEE),
      'genericButtonTextColor': const Color(0xFFE63946),
      'genericSmsEditTextBackground': Colors.white,
      'genericSmsEditTextTextColor': Colors.black,
      'lineColor': const Color(0xFF457B9D),
    },
  };
}
