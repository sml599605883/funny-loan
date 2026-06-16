import 'package:flutter/material.dart';

import '../../../../theme/screen_adapter.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.titleColor = Colors.white,
  });

  final String title;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: ScreenAdapter.edgeInsetsOnly(top: 3, bottom: 10),
        child: Stack(
          children: [
            Positioned(
              top: 9.h,
              left: 0,
              right: 0,
              child: Container(
                height: 5.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8A2E),
                  borderRadius: BorderRadius.circular(5.r),
                ),
              ),
            ),
            Padding(
              padding: ScreenAdapter.edgeInsetsSymmetric(horizontal: 6),
              child: Text(
                title,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
