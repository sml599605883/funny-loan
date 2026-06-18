import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'retention_popup.dart';

class CertificationRetentionGuard {
  CertificationRetentionGuard._();

  static Future<void> handleBack({
    required String type,
    required String productId,
    required VoidCallback onDefaultBack,
  }) async {
    final shown = await RetentionPopup.show(
      type: type,
      productId: productId,
      onLeftTap: onDefaultBack,
    );
    if (!shown) {
      onDefaultBack();
    }
  }

  static VoidCallback backHandler({
    required String type,
    required String productId,
  }) {
    return () {
      unawaited(
        handleBack(
          type: type,
          productId: productId,
          onDefaultBack: () => Get.back<void>(),
        ),
      );
    };
  }
}
