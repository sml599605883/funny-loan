import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/screen_adapter.dart';
import '../../models/app_home_model.dart';

class TopHeroSection extends StatelessWidget {
  const TopHeroSection({super.key, required this.card, this.onTap});

  final HomeCardModel card;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final creditMetrics = _displayCreditList(card.creditList);
    final hasCreditMetrics = creditMetrics.isNotEmpty;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/home/home_recommendation_bg.png'),
                fit: BoxFit.fill,
              ),
            ),
            padding: ScreenAdapter.edgeInsetsOnly(left: 21, top: 11, right: 21),
            child: Column(
              children: [
                Container(
                  height: 33.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8A2E),
                    borderRadius: BorderRadius.circular(17.r),
                  ),
                  padding: ScreenAdapter.edgeInsetsSymmetric(
                    horizontal: 26,
                    vertical: 7,
                  ),
                  child: Text(
                    card.productName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(height: 25.h),
                Text(
                  card.maxAmountDesc,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  card.maxAmount,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 36.sp,
                    height: 1.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 35.h),
                Container(
                  height: 60.h,
                  decoration: BoxDecoration(
                    color: AppColors.homeProcessTrack,
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  padding: ScreenAdapter.edgeInsetsSymmetric(
                    horizontal: hasCreditMetrics ? 32 : 15,
                    vertical: 12,
                  ),
                  child: hasCreditMetrics
                      ? _CreditMetricRow(metrics: creditMetrics)
                      : Row(
                          children: [
                            Expanded(
                              child: _MetricTile(
                                icon:
                                    'assets/home/home_status_icon_profile.png',
                                value: card.termInfo,
                                label: card.termInfoDesc,
                              ),
                            ),
                            Container(
                              width: 2.w,
                              height: 35.h,
                              color: Colors.white,
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: _MetricTile(
                                icon:
                                    'assets/home/home_status_icon_identity.png',
                                value: card.rateInfo,
                                label: card.rateInfoDesc,
                              ),
                            ),
                          ],
                        ),
                ),
                SizedBox(height: 16.h),
                SizedBox(
                  height: 56.h,
                  child: Center(
                    child: Text(
                      card.buttonText,
                      style: TextStyle(
                        color: const Color(0xFF3A57B0),
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 11.w,
            top: -14.h,
            child: SizedBox(
              width: 55.w,
              height: 55.w,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/home/home_avatar_ring.png',
                    width: 55.w,
                    height: 55.w,
                  ),
                  Container(
                    width: 41.w,
                    height: 41.w,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: card.productLogo.isEmpty
                        ? null
                        : Image.network(
                            card.productLogo,
                            fit: BoxFit.cover,
                            errorBuilder: (_, error, stackTrace) =>
                                const SizedBox.shrink(),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<HomeCreditStepModel> _displayCreditList(
    List<HomeCreditStepModel> creditList,
  ) {
    if (creditList.length <= 2) {
      return creditList;
    }
    return <HomeCreditStepModel>[creditList.first, creditList.last];
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final String icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(icon, width: 27.w, height: 27.w),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CreditMetricRow extends StatelessWidget {
  const _CreditMetricRow({required this.metrics});

  final List<HomeCreditStepModel> metrics;

  @override
  Widget build(BuildContext context) {
    if (metrics.length == 1) {
      return Center(child: _CreditMetricTile(metric: metrics.first));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CreditMetricTile(metric: metrics.first, fixedWidth: true),
        Container(
          width: 2.w,
          height: 35.h,
          margin: ScreenAdapter.edgeInsetsSymmetric(horizontal: 27),
          color: Colors.white,
        ),
        _CreditMetricTile(metric: metrics.last, fixedWidth: true),
      ],
    );
  }
}

class _CreditMetricTile extends StatelessWidget {
  const _CreditMetricTile({required this.metric, this.fixedWidth = false});

  final HomeCreditStepModel metric;
  final bool fixedWidth;

  @override
  Widget build(BuildContext context) {
    final label = metric.periodDesc.isNotEmpty ? metric.periodDesc : '';

    return SizedBox(
      key: ValueKey<String>('credit_metric_${metric.period}_$label'),
      width: fixedWidth ? 80.w : null,
      child: Row(
        mainAxisSize: fixedWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Container(
            constraints: BoxConstraints(minWidth: 29.w),
            padding: ScreenAdapter.edgeInsetsOnly(
              left: 7,
              top: 1,
              right: 7,
              bottom: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.homeAccent,
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              metric.period,
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color.fromRGBO(255, 215, 127, 1),
                fontSize: 20.sp,
                height: 24 / 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Flexible(
            fit: fixedWidth ? FlexFit.tight : FlexFit.loose,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black,
                fontSize: 14.sp,
                height: 17 / 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
