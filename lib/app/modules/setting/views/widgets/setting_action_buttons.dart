import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/screen_adapter.dart';

class SettingActionButtons extends StatelessWidget {
  const SettingActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: ScreenAdapter.edgeInsetsOnly(top: 14, bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25.r),
          ),
          child: Text(
            'Deactivate Account',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFFA1A1A1),
              fontSize: 18.sp,
              height: 22 / 18,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          width: double.infinity,
          padding: ScreenAdapter.edgeInsetsOnly(top: 13, bottom: 15),
          decoration: BoxDecoration(
            color: AppColors.loginPrimary,
            borderRadius: BorderRadius.circular(25.r),
          ),
          child: Text(
            'Logout',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              height: 22 / 18,
            ),
          ),
        ),
      ],
    );
  }
}
