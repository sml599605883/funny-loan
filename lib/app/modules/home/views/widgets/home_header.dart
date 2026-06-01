import 'package:flutter/material.dart';

import '../../../../theme/screen_adapter.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Hi！Welcome',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Image.asset(
          'assets/home/home_avatar_badge.png',
          width: 34.w,
          height: 34.w,
        ),
      ],
    );
  }
}
