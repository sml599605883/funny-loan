import 'package:flutter/material.dart';

import '../../../../routes/navigation_helper.dart';
import '../../../../theme/screen_adapter.dart';

class SettingHeader extends StatelessWidget {
  const SettingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: NavigationHelper.back,
          child: Padding(
            padding: ScreenAdapter.edgeInsetsOnly(right: 16),
            child: Image.asset(
              'assets/setting/setting_back_icon.png',
              width: 23.w,
              height: 26.h,
              fit: BoxFit.contain,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: ScreenAdapter.edgeInsetsOnly(right: 39),
            child: Text(
              'Setting',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                height: 24 / 20,
                letterSpacing: 0.07756407558917999,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
