import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/screen_adapter.dart';

class OrderListCard extends StatelessWidget {
  const OrderListCard({
    super.key,
    required this.statusCode,
    this.appName = 'App Name',
    this.productLogo = '',
    this.statusText = '',
    this.amountLabel = 'Loan Amount',
    this.amountText = '₱ 20,000',
    this.dueDateLabel = 'Due Date',
    this.dueDateText = '2026/05/13',
    this.actionText = 'Repay Now',
    this.onTap,
  });

  final String statusCode;
  final String appName;
  final String productLogo;
  final String statusText;
  final String amountLabel;
  final String amountText;
  final String dueDateLabel;
  final String dueDateText;
  final String actionText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = _OrderCardStyle.fromStatusCode(statusCode);
    final displayedBadgeText = statusText;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
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
              padding: ScreenAdapter.edgeInsetsOnly(
                left: 12,
                top: 14,
                right: 12,
                bottom: 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: style.headerGradient,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
              ),
              child: Row(
                children: [
                  _buildProductLogo(),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      appName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        height: 17 / 14,
                      ),
                    ),
                  ),
                  SizedBox(width: 5.w),
                  SizedBox(
                    width: 80.w,
                    child: Text(
                      displayedBadgeText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: style.accentColor,
                        fontSize: 12.sp,
                        height: 14 / 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: ScreenAdapter.edgeInsetsOnly(
                left: 12,
                top: 5,
                right: 12,
              ),
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
                        amountLabel,
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
                            dueDateLabel,
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
                              color: style.accentColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              height: 20 / 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        padding: ScreenAdapter.edgeInsetsOnly(
                          left: 15,
                          top: 9,
                          right: 15,
                          bottom: 8,
                        ),
                        decoration: BoxDecoration(
                          color: style.accentColor,
                          borderRadius: BorderRadius.circular(100.r),
                        ),
                        child: Text(
                          actionText,
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
      ),
    );
  }

  Widget _buildProductLogo() {
    final logoUrl = productLogo.trim();
    if (logoUrl.isNotEmpty) {
      return Image.network(
        logoUrl,
        width: 20.w,
        height: 20.h,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildFallbackLogo(),
      );
    }
    return _buildFallbackLogo();
  }

  Widget _buildFallbackLogo() {
    return Image.asset(
      'assets/home/home_status_icon_identity.png',
      width: 20.w,
      height: 20.h,
      fit: BoxFit.contain,
    );
  }
}

class _OrderCardStyle {
  const _OrderCardStyle({
    required this.accentColor,
    required this.headerGradient,
  });

  final Color accentColor;
  final List<Color> headerGradient;

  static const _redStatusCodes = <String>{'180', '174'};

  factory _OrderCardStyle.fromStatusCode(String statusCode) {
    if (_redStatusCodes.contains(statusCode.trim())) {
      return const _OrderCardStyle(
        accentColor: AppColors.orderStatusRed,
        headerGradient: <Color>[
          AppColors.orderHeaderRedTop,
          AppColors.orderHeaderRedBottom,
        ],
      );
    }
    return const _OrderCardStyle(
      accentColor: AppColors.orderStatusDefault,
      headerGradient: <Color>[
        AppColors.orderHeaderDefaultTop,
        AppColors.orderHeaderDefaultBottom,
      ],
    );
  }
}
