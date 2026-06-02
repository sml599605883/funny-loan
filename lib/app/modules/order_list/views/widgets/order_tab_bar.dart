import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/screen_adapter.dart';

class OrderTabBar extends StatelessWidget {
  const OrderTabBar({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  static const labels = <String>[
    'All order',
    'Outstanding',
    'Overdue',
    'Settled',
  ];

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        children: List<Widget>.generate(labels.length, (index) {
          final isSelected = index == currentIndex;
          return Expanded(
            child: Stack(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(index),
                  child: Container(
                    height: 36.h,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.mineAccent
                          : Colors.transparent,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(index == 0 ? 18.r : 0),
                        bottomLeft: Radius.circular(index == 0 ? 18.r : 0),
                        topRight: Radius.circular(
                          index == labels.length - 1 ? 18.r : 0,
                        ),
                        bottomRight: Radius.circular(
                          index == labels.length - 1 ? 18.r : 0,
                        ),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      labels[index],
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.orderSegmentText,
                        fontSize: 12.sp,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        height: 18 / 12,
                      ),
                    ),
                  ),
                ),
                if (index != labels.length - 1)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 1.w,
                      color: AppColors.orderSegmentDivider,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
