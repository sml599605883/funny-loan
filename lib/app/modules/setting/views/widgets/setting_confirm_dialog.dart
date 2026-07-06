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
  /*
"标题：Wait, before you go…
内容：Outstanding balances must be repaid first. All data and pre-approved limits will be lost, and you'll reapply from scratch.
按钮：Delete  | Keep My Account"
*/
  String get _title => switch (type) {
    SettingDialogType.logout => 'Ready to sign out?',
    SettingDialogType.deleteAccount => 'Wait, before you go…',
  };

  String get _message => switch (type) {
    SettingDialogType.logout =>
      'Your session and any active loan offers will be saved. Sign in again anytime to continue.',
    SettingDialogType.deleteAccount =>
      'Outstanding balances must be repaid first. All data and pre-approved limits will be lost, and you\'ll reapply from scratch.',
  };

  String get _leftAction => switch (type) {
    SettingDialogType.logout => 'Sign Out',
    SettingDialogType.deleteAccount => 'Delete',
  };

  String get _rightAction => switch (type) {
    SettingDialogType.logout => 'Keep Me Logged In',
    SettingDialogType.deleteAccount => 'Keep My Account',
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
                  Spacer(),
                  Container(
                    height: 48.h,
                    margin: EdgeInsets.only(bottom: 17.h),
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
