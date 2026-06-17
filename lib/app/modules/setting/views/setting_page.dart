import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import '../../../core/storage/app_data_store.dart';
import '../../../network/api/api_service.dart';
import '../../../network/errors/network_error_mapper.dart';
import '../../../routes/navigation_helper.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/screen_adapter.dart';
import 'widgets/setting_confirm_dialog.dart';
import 'widgets/setting_action_buttons.dart';
import 'widgets/setting_header.dart';
import 'widgets/setting_info_card.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  Future<void> _showLogoutDialog() async {
    await Get.dialog<void>(
      SettingConfirmDialog(type: SettingDialogType.logout, onConfirm: _logout),
      barrierColor: AppColors.settingDialogBarrier,
      transitionDuration: Duration.zero,
    );
  }

  Future<void> _showDeactivateDialog() async {
    await Get.dialog<void>(
      SettingConfirmDialog(
        type: SettingDialogType.deleteAccount,
        onConfirm: _deleteAccount,
      ),
      barrierColor: AppColors.settingDialogBarrier,
      transitionDuration: Duration.zero,
    );
  }

  Future<void> _logout() async {
    await _submitAccountAction(
      () => Get.find<ApiService>().logout(const <String, dynamic>{}),
    );
  }

  Future<void> _deleteAccount() async {
    await _submitAccountAction(
      () => Get.find<ApiService>().deleteAccount(const <String, dynamic>{}),
    );
  }

  Future<void> _submitAccountAction(Future<void> Function() action) async {
    try {
      EasyLoading.show();
      await action();
      await AppDataStore.removePersistent(AppDataStore.persistedTokenKey);
      AppDataStore.clearCache();
      EasyLoading.dismiss();
      NavigationHelper.offAllToAppHome();
    } catch (error) {
      EasyLoading.dismiss();
      EasyLoading.showError(NetworkErrorMapper.map(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: AppColors.defaultBackgroundGradient,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: ScreenAdapter.edgeInsetsOnly(
              left: 20,
              top: 16,
              right: 20,
              bottom: 20,
            ),
            child: Column(
              children: [
                const SettingHeader(),
                SizedBox(height: 70.h),
                const SettingInfoCard(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            height: 110.h,
            color: Colors.transparent,
            padding: ScreenAdapter.edgeInsetsOnly(left: 36, right: 36),
            child: SettingActionButtons(
              onDeactivateTap: _showDeactivateDialog,
              onLogoutTap: _showLogoutDialog,
            ),
          ),
        ),
      ),
    );
  }
}
