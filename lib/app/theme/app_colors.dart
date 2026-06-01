import 'package:flutter/material.dart';

abstract class AppColors {
  static const gradientStart = Color(0xFF8FC4FB);
  static const gradientEnd = Color(0xFF2166CC);

  static const defaultBackgroundGradient = <Color>[gradientStart, gradientEnd];

  static const loginPrimary = Color(0xFF3A57B0);
  static const loginCardSurface = Color(0xFFEAF1FD);
  static const loginCardShadow = Color(0x1F28498F);
  static const loginButtonDisabled = Color(0xFF9CABD9);
  static const loginInputDivider = Color(0xFFD8D8D8);
  static const loginPlaceholder = Color(0xFFC5C5C5);
  static const loginCountdown = Color(0xFFBDBDBD);
  static const loginPolicyHighlight = Color(0xFFFCD52F);
}
