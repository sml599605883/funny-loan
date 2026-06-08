import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import '../../../core/storage/app_data_store.dart';
import '../../../network/api/api_service.dart';
import '../../../network/core/common_params_builder.dart';
import '../../../network/errors/network_error_mapper.dart';
import '../../../network/network_module.dart';
import '../../../routes/navigation_helper.dart';

class LoginController extends GetxController {
  static const toastDuration = Duration(seconds: 2);

  final phoneController = TextEditingController();
  final codeController = TextEditingController();
  final phoneFocusNode = FocusNode();
  final codeFocusNode = FocusNode();

  final agreed = true.obs;
  final countdown = 0.obs;
  final phoneText = ''.obs;
  final codeText = ''.obs;
  final canRequestCode = false.obs;
  final canSubmit = false.obs;
  final isRequestingCode = false.obs;
  final isSubmitting = false.obs;

  Timer? _countdownTimer;

  @override
  void onInit() {
    super.onInit();
    phoneController.addListener(_syncPhoneText);
    codeController.addListener(_syncCodeText);
  }

  @override
  void onReady() {
    super.onReady();
    phoneController.text =
        AppDataStore.getPersistentString(AppDataStore.persistedPhoneKey) ?? '';
  }

  void toggleAgreement() {
    agreed.value = !agreed.value;
    _refreshSubmitState();
  }

  Future<void> requestCode() async {
    if (!canRequestCode.value ||
        countdown.value > 0 ||
        isRequestingCode.value) {
      return;
    }
    final apiService = _apiService;
    if (apiService == null) {
      EasyLoading.showToast('Service is not ready yet');
      return;
    }
    isRequestingCode.value = true;
    try {
      EasyLoading.show(status: 'Loading...');
      final response = await apiService.requestLoginSmsCode({
        'grieving': phoneText.value.trim(),
      });
      EasyLoading.showSuccess(response.message);
      _startCountdown();
      codeFocusNode.requestFocus();
    } catch (error) {
      EasyLoading.dismiss();
      EasyLoading.showToast(_errorMessage(error));
    } finally {
      isRequestingCode.value = false;
      _refreshSubmitState();
    }
  }

  Future<void> submit() async {
    if (!canSubmit.value || isSubmitting.value) {
      return;
    }
    final apiService = _apiService;
    if (apiService == null) {
      EasyLoading.showToast('Service is not ready yet');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    isSubmitting.value = true;
    _refreshSubmitState();
    try {
      EasyLoading.show(status: 'Loading...');
      final response = await apiService.loginOrRegisterWithCode({
        'puristic': phoneText.value.trim(),
        'supermarket': codeText.value.trim(),
      });
      EasyLoading.dismiss();
      final responsePhone = response.data['puristic'].stringValue.trim();
      final responseToken = response.data['manioc'].stringValue.trim();
      final phone = responsePhone.isEmpty
          ? phoneText.value.trim()
          : responsePhone;
      await AppDataStore.setPersistentString(
        AppDataStore.persistedPhoneKey,
        phone,
      );
      await AppDataStore.setPersistentString(
        AppDataStore.persistedTokenKey,
        responseToken,
      );
      CommonParamsBuilder.updateSessionId(responseToken);
      NavigationHelper.offAllToHome();
    } catch (error) {
      EasyLoading.dismiss();
      codeController.clear();
      EasyLoading.showToast(_errorMessage(error), duration: toastDuration);
      Future<void>.delayed(toastDuration, () {
        if (isClosed) {
          return;
        }
        codeFocusNode.requestFocus();
      });
    } finally {
      isSubmitting.value = false;
      _refreshSubmitState();
    }
  }

  void onPrivacyPolicyTap() {
    log('Privacy Policy clicked on login page.');
  }

  void _syncPhoneText() {
    phoneText.value = phoneController.text;
    canRequestCode.value = phoneText.value.trim().length >= 10;
    _refreshSubmitState();
  }

  void _syncCodeText() {
    codeText.value = codeController.text;
    _refreshSubmitState();
    if (codeText.value.trim().length == 6 &&
        canSubmit.value &&
        !isSubmitting.value) {
      unawaited(submit());
    }
  }

  void _refreshSubmitState() {
    canSubmit.value =
        agreed.value &&
        canRequestCode.value &&
        codeText.value.trim().length >= 6 &&
        !isSubmitting.value;
  }

  ApiService? get _apiService {
    if (!Get.isRegistered<NetworkModule>()) {
      return null;
    }
    return Get.find<NetworkModule>().apiService;
  }

  void _startCountdown() {
    countdown.value = 59;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown.value <= 1) {
        countdown.value = 0;
        timer.cancel();
        _refreshSubmitState();
        return;
      }
      countdown.value--;
    });
  }

  String _errorMessage(Object error) {
    return NetworkErrorMapper.map(error);
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    phoneController.dispose();
    codeController.dispose();
    phoneFocusNode.dispose();
    codeFocusNode.dispose();
    super.onClose();
  }
}
