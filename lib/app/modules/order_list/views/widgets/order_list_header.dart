import 'package:flutter/material.dart';

import '../../../../routes/navigation_helper.dart';
import '../../../../theme/screen_adapter.dart';

class OrderListHeader extends StatelessWidget {
  const OrderListHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Hi',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                  height: 26 / 22,
                  letterSpacing: 0.08532048761844635,
                ),
              ),
              TextSpan(
                text: '！',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w600,
                  height: 26 / 22,
                ),
              ),
              TextSpan(
                text: 'Welcome',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                  height: 26 / 22,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => NavigationHelper.toDetail(arguments: 'Customer Service'),
          child: Image.asset(
            'assets/home/home_avatar_badge.png',
            width: 34.w,
            height: 34.h,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}
