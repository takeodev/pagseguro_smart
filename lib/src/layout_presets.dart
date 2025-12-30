import 'package:flutter/material.dart';
import 'package:pagseguro_smart/src/models/styledata_model.dart';

enum LayoutPreset {
  pagSeguro,
  darkBlue,
  darkGreen,
  lightCustom,
  warmSunset,
  warmLight,
}

class LayoutPresets {
  static final Map<LayoutPreset, StyleDataModel> _presets = {
    /// PagSeguro
    LayoutPreset.pagSeguro: const StyleDataModel(
      headTextColor: Color(0xFFFFFFFF),
      headBackgroundColor: Color(0xFF323232),
      contentTextColor: Color(0xFFE0E0E0),
      contentTextValue1Color: Color(0xFF53D331),
      contentTextValue2Color: Color(0xFFAAAAAA),
      positiveButtonTextColor: Color(0xFF000000),
      positiveButtonBackground: Color(0xFF53D331),
      negativeButtonTextColor: Color(0xFFFFFFFF),
      negativeButtonBackground: Color(0xFF424242),
      genericButtonBackground: Color(0xFF323232),
      genericButtonTextColor: Color(0xFF53D331),
      genericSmsEditTextBackground: Color(0xFF2B2B2B),
      genericSmsEditTextTextColor: Color(0xFFFFFFFF),
      lineColor: Color(0xFF333333),
    ),

    /// 🔵 Dark Blue
    LayoutPreset.darkBlue: const StyleDataModel(
      headTextColor: Color(0xFFFFFFFF),
      headBackgroundColor: Color(0xFF0D1B2A),
      contentTextColor: Color(0xFFE0E1DD),
      contentTextValue1Color: Color(0xFF4CC9F0),
      contentTextValue2Color: Color(0xFFFFFFFF),
      positiveButtonTextColor: Color(0xFFFFFFFF),
      positiveButtonBackground: Color(0xFF4CC9F0),
      negativeButtonTextColor: Color(0xFFFFFFFF),
      negativeButtonBackground: Color(0xFF415A77),
      genericButtonBackground: Color(0xFF1B263B),
      genericButtonTextColor: Color(0xFF4CC9F0),
      genericSmsEditTextBackground: Color(0xFF1B263B),
      genericSmsEditTextTextColor: Color(0xFFFFFFFF),
      lineColor: Color(0xFF778DA9),
    ),

    /// 🟢 Dark Green
    LayoutPreset.darkGreen: const StyleDataModel(
      headTextColor: Color(0xFFFFFFFF),
      headBackgroundColor: Color(0xFF1B4332),
      contentTextColor: Color(0xFFD8F3DC),
      contentTextValue1Color: Color(0xFF52B788),
      contentTextValue2Color: Color(0xFFFFFFFF),
      positiveButtonTextColor: Color(0xFFFFFFFF),
      positiveButtonBackground: Color(0xFF52B788),
      negativeButtonTextColor: Color(0xFFFFFFFF),
      negativeButtonBackground: Color(0xFF2D6A4F),
      genericButtonBackground: Color(0xFF081C15),
      genericButtonTextColor: Color(0xFF52B788),
      genericSmsEditTextBackground: Color(0xFF081C15),
      genericSmsEditTextTextColor: Color(0xFFFFFFFF),
      lineColor: Color(0xFF95D5B2),
    ),

    /// ☀️ Light Custom
    LayoutPreset.lightCustom: const StyleDataModel(
      headTextColor: Color(0xFF000000),
      headBackgroundColor: Color(0xFFF1FAEE),
      contentTextColor: Color(0xFF1D3557),
      contentTextValue1Color: Color(0xFFE63946),
      contentTextValue2Color: Color(0xFF000000),
      positiveButtonTextColor: Color(0xFFFFFFFF),
      positiveButtonBackground: Color(0xFFE63946),
      negativeButtonTextColor: Color(0xFF000000),
      negativeButtonBackground: Color(0xFFA8DADC),
      genericButtonBackground: Color(0xFFF1FAEE),
      genericButtonTextColor: Color(0xFFE63946),
      genericSmsEditTextBackground: Color(0xFFFFFFFF),
      genericSmsEditTextTextColor: Color(0xFF000000),
      lineColor: Color(0xFF457B9D),
    ),

    /// 🔥 Warm Sunset
    LayoutPreset.warmSunset: const StyleDataModel(
      headTextColor: Color(0xFFFFFFFF),
      headBackgroundColor: Color(0xFF8B0000),
      contentTextColor: Color(0xFFFFF3E0),
      contentTextValue1Color: Color(0xFFFFC107),
      contentTextValue2Color: Color(0xFFFFFFFF),
      positiveButtonTextColor: Color(0xFFFFFFFF),
      positiveButtonBackground: Color(0xFFD84315),
      negativeButtonTextColor: Color(0xFFFFFFFF),
      negativeButtonBackground: Color(0xFF5D4037),
      genericButtonBackground: Color(0xFFBF360C),
      genericButtonTextColor: Color(0xFFFFC107),
      genericSmsEditTextBackground: Color(0xFF3E2723),
      genericSmsEditTextTextColor: Color(0xFFFFFFFF),
      lineColor: Color(0xFFFFB300),
    ),

    /// ☀️ Warm Light
    LayoutPreset.warmLight: const StyleDataModel(
      headTextColor: Color(0xFF5D1A00),
      headBackgroundColor: Color(0xFFFFF3E0),
      contentTextColor: Color(0xFF4E342E),
      contentTextValue1Color: Color(0xFFFF9800),
      contentTextValue2Color: Color(0xFF5D1A00),
      positiveButtonTextColor: Color(0xFFFFFFFF),
      positiveButtonBackground: Color(0xFFE65100),
      negativeButtonTextColor: Color(0xFF6D4C41),
      negativeButtonBackground: Color(0xFFFFE0B2),
      genericButtonBackground: Color(0xFFFFCC80),
      genericButtonTextColor: Color(0xFFBF360C),
      genericSmsEditTextBackground: Color(0xFFFFFFFF),
      genericSmsEditTextTextColor: Color(0xFF3E2723),
      lineColor: Color(0xFFFFB74D),
    ),
  };

  static StyleDataModel? of(LayoutPreset? preset) {
    if (preset == null) return null;
    return _presets[preset] ??
        (throw ArgumentError('LayoutPreset Inexistente: $preset'));
  }
}
