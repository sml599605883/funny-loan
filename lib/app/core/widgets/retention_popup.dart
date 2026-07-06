import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:funny_loan/app/theme/screen_adapter.dart';
import 'package:get/get.dart';

import '../../network/api/api_service.dart';
import '../../theme/app_colors.dart';

class RetentionPopup {
  RetentionPopup._();

  static const leftButtonKey = Key('retention_popup_left_button');
  static const rightButtonKey = Key('retention_popup_right_button');

  static Future<bool> show({
    required String type,
    required String productId,
    required VoidCallback onLeftTap,
    ApiService? apiService,
  }) async {
    final normalizedType = type.trim();
    final normalizedProductId = productId.trim();
    if (normalizedType.isEmpty || normalizedProductId.isEmpty) {
      return false;
    }

    final response = await (apiService ?? Get.find<ApiService>())
        .fetchRetentionPopup(<String, dynamic>{
          'dominances': normalizedType,
          'skoals': normalizedProductId,
        });
    final dialog = response.data['fidelismo'];
    final imageUrl = dialog['blessedness'].stringValue.trim().isNotEmpty
        ? dialog['blessedness'].stringValue.trim()
        : dialog['sidearms'].stringValue.trim();
    if (imageUrl.isEmpty) {
      return false;
    }

    await Get.dialog<void>(
      RetentionPopupContent(imageUrl: imageUrl, onLeftTap: onLeftTap),
      barrierColor: AppColors.certificationUploadDialogBarrier,
      transitionDuration: Duration.zero,
    );
    return true;
  }
}

class RetentionPopupContent extends StatelessWidget {
  const RetentionPopupContent({
    super.key,
    required this.imageUrl,
    required this.onLeftTap,
  });

  static const _designWidth = 375.0;
  static const _dialogLeft = 30.0;
  static const _dialogTop = 188.0;
  static const _dialogWidth = 315.0;
  static const _dialogHeight = 361.0;
  static const _leftButton = Rect.fromLTWH(55, 483, 128, 48);
  static const _rightButton = Rect.fromLTWH(193, 483, 128, 48);

  final String imageUrl;
  final VoidCallback onLeftTap;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final scale = math.min(
      screenSize.width / _designWidth,
      screenSize.height / _dialogHeight,
    );
    final dialogWidth = _dialogWidth * scale;
    final dialogHeight = _dialogHeight * scale;

    return Center(
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                imageUrl,
                fit: BoxFit.fill,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
            _RetentionPopupButton(
              key: RetentionPopup.leftButtonKey,
              rect: _buttonRect(_leftButton, scale),
              label: 'Exit',
              backgroundColor: Colors.white,
              textColor: Colors.black,
              onTap: () {
                Get.back<void>();
                onLeftTap();
              },
            ),
            _RetentionPopupButton(
              key: RetentionPopup.rightButtonKey,
              rect: _buttonRect(_rightButton, scale),
              label: 'Continue',
              backgroundColor: const Color(0xFF3A57B0),
              textColor: Colors.white,
              onTap: Get.back<void>,
            ),
          ],
        ),
      ),
    );
  }

  Rect _buttonRect(Rect designRect, double scale) {
    return Rect.fromLTWH(
      (designRect.left - _dialogLeft) * scale,
      (designRect.top - _dialogTop) * scale,
      designRect.width * scale,
      designRect.height * scale,
    );
  }
}

class _RetentionPopupButton extends StatelessWidget {
  const _RetentionPopupButton({
    super.key,
    required this.rect,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  final Rect rect;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(40.r),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18.sp,
              color: textColor,
              fontWeight: .bold,
            ),
          ),
        ),
      ),
    );
  }
}
