import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/screen_adapter.dart';

enum SettingDialogType { logout, deleteAccount }

class SettingConfirmDialog extends StatelessWidget {
  const SettingConfirmDialog({
    super.key,
    required this.type,
    required this.onConfirm,
  });

  static const String illustrationAsset =
      'assets/setting/setting_confirm_dialog_illustration.png';

  final SettingDialogType type;
  final VoidCallback onConfirm;

  String get _title => switch (type) {
    SettingDialogType.logout => 'Leaving Already?',
    SettingDialogType.deleteAccount => 'Delete Your Account?',
  };

  String get _message => switch (type) {
    SettingDialogType.logout =>
      'Log in anytime to continue your application and check new loan offers.',
    SettingDialogType.deleteAccount =>
      'You\'ll need to verify again next time, and current benefits may not be available.',
  };

  String get _leftAction => switch (type) {
    SettingDialogType.logout => 'Log Out',
    SettingDialogType.deleteAccount => 'Delete Account',
  };

  String get _rightAction => switch (type) {
    SettingDialogType.logout => 'Stay',
    SettingDialogType.deleteAccount => 'Stay',
  };

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenSize = MediaQuery.sizeOf(context);
          final width = screenSize.width - 70.w;
          // final scale = width / 315;

          return Center(
            child: Container(
              width: width,
              height: width * (333.0 / 305.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.r),
                image: DecorationImage(
                  image: AssetImage(illustrationAsset),
                  fit: BoxFit.fill,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 129.w),
                  Text(
                    _title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.settingDialogTitle,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 20.w),
                  Container(
                    height: 60.h,
                    padding: EdgeInsets.symmetric(horizontal: 30.w),
                    child: Text(
                      _message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.settingDialogBody,
                        fontSize: 16.sp,
                        height: 1.1,
                      ),
                    ),
                  ),
                  SizedBox(height: 36.w),
                  Container(
                    height: 48.h,
                    padding: EdgeInsets.only(left: 18.w, right: 18.w),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              Navigator.of(context).pop();
                              onConfirm();
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color(0xFFE6E6E6),
                                borderRadius: BorderRadius.circular(24.r),
                              ),
                              alignment: .center,
                              child: Text(
                                _leftAction,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.settingDialogSecondaryAction,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: Navigator.of(context).pop,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color(0xFF3A57B0),
                                borderRadius: BorderRadius.circular(24.r),
                              ),
                              alignment: .center,
                              child: Text(
                                _rightAction,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.mineServiceCard,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w700,
                                  height: 22 / 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
