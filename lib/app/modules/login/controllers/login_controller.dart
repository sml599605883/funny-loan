import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/navigation_helper.dart';

class LoginController extends GetxController {
  final phoneController = TextEditingController();
  final codeController = TextEditingController();

  final agreed = true.obs;
  final countdown = 0.obs;
  final phoneText = ''.obs;
  final codeText = ''.obs;
  final canRequestCode = false.obs;
  final canSubmit = false.obs;

  Timer? _countdownTimer;

  @override
  void onInit() {
    super.onInit();
    phoneController.addListener(_syncPhoneText);
    codeController.addListener(_syncCodeText);
  }

  void toggleAgreement() {
    agreed.value = !agreed.value;
    _refreshSubmitState();
  }

  void requestCode() {
    if (!canRequestCode.value || countdown.value > 0) {
      return;
    }
    countdown.value = 59;
    _refreshSubmitState();
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown.value <= 1) {
        countdown.value = 0;
        timer.cancel();
        return;
      }
      countdown.value--;
    });
  }

  void submit() {
    if (!canSubmit.value) {
      return;
    }
    NavigationHelper.offAllToHome();
  }

  void _syncPhoneText() {
    phoneText.value = phoneController.text;
    canRequestCode.value = phoneText.value.trim().length >= 10;
    _refreshSubmitState();
  }

  void _syncCodeText() {
    codeText.value = codeController.text;
    _refreshSubmitState();
  }

  void _refreshSubmitState() {
    canSubmit.value =
        agreed.value &&
        canRequestCode.value &&
        codeText.value.trim().length >= 6;
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    phoneController.dispose();
    codeController.dispose();
    super.onClose();
  }
}
