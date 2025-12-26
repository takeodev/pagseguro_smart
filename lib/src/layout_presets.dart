import 'package:flutter/material.dart';

enum LayoutPreset {
  pagseguroDefault,
  darkBlue,
  darkGreen,
  lightCustom,
  warmSunset,
  warmLight,
}

class LayoutPresets {
  static Map<LayoutPreset, Map<String, Color>> presets = {
    /// Padrão de Exemplo PagSeguro Wrapper
    // https://pagseguro.github.io/pagseguro-sdk-plugpagservicewrapper/-wrapper-p-p-s/br.com.uol.pagseguro.plugpagservice.wrapper/-plug-pag/set-style-data.html
    LayoutPreset.pagseguroDefault: {
      'headTextColor': const Color(0xFF000000),
      'headBackgroundColor': const Color(0xFFE13C70),
      'contentTextColor': const Color(0xFFDFDFE0),
      'contentTextValue1Color': const Color(0xFFFFE000),
      'contentTextValue2Color': const Color(0xFF000000),
      'positiveButtonTextColor': const Color(0xFF000000),
      'positiveButtonBackground': const Color(0xFFFF358C),
      'negativeButtonTextColor': const Color(0xFF777778),
      'negativeButtonBackground': const Color(0xFF000000),
      'genericButtonBackground': const Color(0xFF000000),
      'genericButtonTextColor': const Color(0xFFFF358C),
      'genericSmsEditTextBackground': const Color(0xFF000000),
      'genericSmsEditTextTextColor': const Color(0xFFFF358C),
      'lineColor': const Color(0xFF000000),
    },

    /// 🔵 Dark Blue
    LayoutPreset.darkBlue: {
      'headTextColor': const Color(0xFFFFFFFF),
      'headBackgroundColor': const Color(0xFF0D1B2A),
      'contentTextColor': const Color(0xFFE0E1DD),
      'contentTextValue1Color': const Color(0xFF4CC9F0),
      'contentTextValue2Color': const Color(0xFFFFFFFF),
      'positiveButtonTextColor': const Color(0xFFFFFFFF),
      'positiveButtonBackground': const Color(0xFF4CC9F0),
      'negativeButtonTextColor': const Color(0xFFFFFFFF),
      'negativeButtonBackground': const Color(0xFF415A77),
      'genericButtonBackground': const Color(0xFF1B263B),
      'genericButtonTextColor': const Color(0xFF4CC9F0),
      'genericSmsEditTextBackground': const Color(0xFF1B263B),
      'genericSmsEditTextTextColor': const Color(0xFFFFFFFF),
      'lineColor': const Color(0xFF778DA9),
    },

    /// 🟢 Dark Green
    LayoutPreset.darkGreen: {
      'headTextColor': const Color(0xFFFFFFFF),
      'headBackgroundColor': const Color(0xFF1B4332),
      'contentTextColor': const Color(0xFFD8F3DC),
      'contentTextValue1Color': const Color(0xFF52B788),
      'contentTextValue2Color': const Color(0xFFFFFFFF),
      'positiveButtonTextColor': const Color(0xFFFFFFFF),
      'positiveButtonBackground': const Color(0xFF52B788),
      'negativeButtonTextColor': const Color(0xFFFFFFFF),
      'negativeButtonBackground': const Color(0xFF2D6A4F),
      'genericButtonBackground': const Color(0xFF081C15),
      'genericButtonTextColor': const Color(0xFF52B788),
      'genericSmsEditTextBackground': const Color(0xFF081C15),
      'genericSmsEditTextTextColor': const Color(0xFFFFFFFF),
      'lineColor': const Color(0xFF95D5B2),
    },

    /// ☀️ Light Custom
    LayoutPreset.lightCustom: {
      'headTextColor': const Color(0xFF000000),
      'headBackgroundColor': const Color(0xFFF1FAEE),
      'contentTextColor': const Color(0xFF1D3557),
      'contentTextValue1Color': const Color(0xFFE63946),
      'contentTextValue2Color': const Color(0xFF000000),
      'positiveButtonTextColor': const Color(0xFFFFFFFF),
      'positiveButtonBackground': const Color(0xFFE63946),
      'negativeButtonTextColor': const Color(0xFF000000),
      'negativeButtonBackground': const Color(0xFFA8DADC),
      'genericButtonBackground': const Color(0xFFF1FAEE),
      'genericButtonTextColor': const Color(0xFFE63946),
      'genericSmsEditTextBackground': const Color(0xFFFFFFFF),
      'genericSmsEditTextTextColor': const Color(0xFF000000),
      'lineColor': const Color(0xFF457B9D),
    },

    /// 🔥 Warm Sunset
    LayoutPreset.warmSunset: {
      'headTextColor': const Color(0xFFFFFFFF),
      'headBackgroundColor': const Color(0xFF8B0000),
      'contentTextColor': const Color(0xFFFFF3E0),
      'contentTextValue1Color': const Color(0xFFFFC107),
      'contentTextValue2Color': const Color(0xFFFFFFFF),
      'positiveButtonTextColor': const Color(0xFFFFFFFF),
      'positiveButtonBackground': const Color(0xFFD84315),
      'negativeButtonTextColor': const Color(0xFFFFFFFF),
      'negativeButtonBackground': const Color(0xFF5D4037),
      'genericButtonBackground': const Color(0xFFBF360C),
      'genericButtonTextColor': const Color(0xFFFFC107),
      'genericSmsEditTextBackground': const Color(0xFF3E2723),
      'genericSmsEditTextTextColor': const Color(0xFFFFFFFF),
      'lineColor': const Color(0xFFFFB300),
    },

    /// ☀️ Warm Light
    LayoutPreset.warmLight: {
      'headTextColor': const Color(0xFF5D1A00),
      'headBackgroundColor': const Color(0xFFFFF3E0),
      'contentTextColor': const Color(0xFF4E342E),
      'contentTextValue1Color': const Color(0xFFFF9800),
      'contentTextValue2Color': const Color(0xFF5D1A00),
      'positiveButtonTextColor': const Color(0xFFFFFFFF),
      'positiveButtonBackground': const Color(0xFFE65100),
      'negativeButtonTextColor': const Color(0xFF6D4C41),
      'negativeButtonBackground': const Color(0xFFFFE0B2),
      'genericButtonBackground': const Color(0xFFFFCC80),
      'genericButtonTextColor': const Color(0xFFBF360C),
      'genericSmsEditTextBackground': const Color(0xFFFFFFFF),
      'genericSmsEditTextTextColor': const Color(0xFF3E2723),
      'lineColor': const Color(0xFFFFB74D),
    },
  };
}
