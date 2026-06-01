import 'package:flutter/material.dart';

import '../../../../theme/screen_adapter.dart';
import '../../models/app_home_model.dart';

class TopHeroSection extends StatelessWidget {
  const TopHeroSection({super.key, required this.card});

  final HomeCardModel card;

  @override
  Widget build(BuildContext context) {
    return Stack(
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
                  color: const Color(0xFFC3D8F7),
                  borderRadius: BorderRadius.circular(30.r),
                ),
                padding: ScreenAdapter.edgeInsetsSymmetric(
                  horizontal: 15,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        icon: 'assets/home/home_status_icon_profile.png',
                        value: card.termInfo,
                        label: card.termInfoDesc,
                      ),
                    ),
                    Container(width: 2.w, height: 35.h, color: Colors.white),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _MetricTile(
                        icon: 'assets/home/home_status_icon_identity.png',
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
    );
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
