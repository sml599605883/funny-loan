import 'package:flutter/material.dart';

import '../../../../core/utils/web_page_opener.dart';
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
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => WebPageOpener.openPath('/#/SuperhighwaySubscribes'),
          child: Image.asset(
            'assets/home/home_avatar_badge.png',
            width: 34.w,
            height: 34.w,
          ),
        ),
      ],
    );
  }
}
