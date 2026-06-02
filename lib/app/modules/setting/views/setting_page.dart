import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/screen_adapter.dart';
import 'widgets/setting_action_buttons.dart';
import 'widgets/setting_header.dart';
import 'widgets/setting_info_card.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

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
            child: const SettingActionButtons(),
          ),
        ),
      ),
    );
  }
}
