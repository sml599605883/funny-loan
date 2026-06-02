import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/screen_adapter.dart';

enum OrderStatusType {
  overdue,
  outstanding,
  settled,
}

class OrderListCard extends StatelessWidget {
  const OrderListCard({
    super.key,
    required this.status,
    this.appName = 'App Name',
    this.amountText = '₱ 20,000',
    this.dueDateText = '2026/05/13',
  });

  final OrderStatusType status;
  final String appName;
  final String amountText;
  final String dueDateText;

  @override
  Widget build(BuildContext context) {
    final badgeColor = switch (status) {
      OrderStatusType.overdue => AppColors.orderStatusOverdue,
      OrderStatusType.outstanding => AppColors.orderStatusOutstanding,
      OrderStatusType.settled => AppColors.orderStatusSettled,
    };
    final headerGradient = switch (status) {
      OrderStatusType.overdue => const [
          Color(0xFFFFE7E7),
          Color(0xFFFFC4C4),
        ],
      OrderStatusType.outstanding => const [
          Color(0xFFFFF4D6),
          Color(0xFFFFD89B),
        ],
      OrderStatusType.settled => const [
          Color(0xFFF8FAFF),
          Color(0xFFDDE8FF),
        ],
    };
    final badgeText = switch (status) {
      OrderStatusType.overdue => 'Overdue',
      OrderStatusType.outstanding => 'Outstanding',
      OrderStatusType.settled => 'Settled',
    };

    return Container(
      width: double.infinity,
      padding: ScreenAdapter.edgeInsetsOnly(bottom: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: ScreenAdapter.edgeInsetsOnly(left: 12, top: 14, right: 12, bottom: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: headerGradient,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.r),
                topRight: Radius.circular(20.r),
              ),
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/home/home_status_icon_identity.png',
                  width: 20.w,
                  height: 20.h,
                  fit: BoxFit.contain,
                ),
                SizedBox(width: 10.w),
                Text(
                  appName,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    height: 17 / 14,
                  ),
                ),
                const Spacer(),
                Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 12.sp,
                    height: 14 / 12,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: ScreenAdapter.edgeInsetsOnly(left: 12, top: 5, right: 12),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      amountText,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w700,
                        height: 31 / 26,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      'Loan Amount',
                      style: TextStyle(
                        color: AppColors.orderLabelText,
                        fontSize: 12.sp,
                        height: 14 / 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Due Date',
                          style: TextStyle(
                            color: AppColors.orderDueLabelText,
                            fontSize: 12.sp,
                            height: 16 / 12,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          dueDateText,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            height: 20 / 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      padding: ScreenAdapter.edgeInsetsOnly(left: 15, top: 9, right: 15, bottom: 8),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(100.r),
                      ),
                      child: Text(
                        'Repay Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          height: 14 / 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
