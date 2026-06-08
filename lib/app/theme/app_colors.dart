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

  static const mineCardBackground = Color(0xFFE6EFFD);
  static const mineAvatarBackground = Color(0xFFDEEAFE);
  static const mineServiceCard = Color(0xFFFFFFFF);
  static const mineServiceTile = Color(0xFFE6EFFD);
  static const mineAccent = Color(0xFFFF8A2E);
  static const mineTextPrimary = Color(0xFF333333);
  static const mineTextSecondary = Color(0xFF292929);

  static const orderSegmentDivider = Color(0xFFF0F0F0);
  static const orderSegmentText = Color(0xFFC6C6C6);
  static const orderStatusOverdue = Color(0xFFD05353);
  static const orderStatusOutstanding = Color(0xFFF4A621);
  static const orderStatusSettled = Color(0xFF6FB26A);
  static const orderLabelText = Color(0xFFB0B0B0);
  static const orderDueLabelText = Color(0xFFCECECE);

  static const certificationTextPrimary = Color(0xFF281001);
  static const certificationBackSurface = Color(0xFFEDEAE5);
  static const certificationHintText = Color(0xFFFFE7B1);
  static const certificationHintSurface = Color(0xFFFF8A2E);
  static const certificationCardSurface = Color(0xFFF5F5F3);
  static const certificationCardHeader = Color(0xFFE1E1DC);
  static const certificationCardLine = Color(0xFFC8C8C2);
  static const certificationDivider = Color(0xFFE1E1DC);
  static const certificationWrongText = Color(0xFF908E8C);
  static const certificationWrongIcon = Color(0xFFE93131);
  static const certificationSubmitStart = Color(0xFFFF984B);
  static const certificationSubmitEnd = Color(0xFFFF5934);
  static const certificationUploadBackground = Color(0xFFF0F0F0);
  static const certificationUploadDialogBarrier = Color(0x99000000);
  static const certificationUploadDialogText = Color(0xFF333333);
  static const certificationUploadDialogDivider = Color(0xFFE7E7E7);
  static const certificationUploadDialogCancelText = Color(0xFF999999);
  static const certificationUploadDialogConfirm = Color(0xFFFF8A2E);
  static const certificationUploadSuccessBorder = Color(0xFFC7C7C7);
  static const certificationUploadSuccessInputBorder = Color(0xFFECEDED);
  static const certificationUploadSuccessLabel = Color(0xFF999999);
  static const certificationUploadSuccessButton = Color(0xFF3A57B0);
}
