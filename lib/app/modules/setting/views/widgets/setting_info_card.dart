import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/screen_adapter.dart';

class SettingInfoCard extends StatelessWidget {
  const SettingInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 33.h,
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            width: double.infinity,
            padding: ScreenAdapter.edgeInsetsOnly(
              left: 12,
              top: 68,
              right: 12,
              bottom: 12,
            ),
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/setting/setting_info_card_bg.png'),
                fit: BoxFit.fill,
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Center(
            child: Image.asset(
              'assets/setting/setting_logo.png',
              width: 80.w,
              height: 80.h,
              fit: BoxFit.contain,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(12.h),
          child: Column(
            children: [
              SizedBox(height: 88.h),
              Text(
                'App Name',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  height: 24 / 20,
                  letterSpacing: 0.07756407558917999,
                ),
              ),
              SizedBox(height: 33.h),
              const _InfoRow(label: 'Website', value: 'XXXXXXXXXXXXXXXXX'),
              SizedBox(height: 12.h),
              const _InfoRow(label: 'E-mail', value: 'XXXXXXXXXXX'),
              SizedBox(height: 12.h),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final version = snapshot.data?.version ?? '1.0.0';
                  return _InfoRow(label: 'Version', value: 'V$version');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ScreenAdapter.edgeInsetsOnly(
        left: 11,
        top: 13,
        right: 10,
        bottom: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.mineServiceTile,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.mineTextPrimary,
              fontSize: 16.sp,
              height: 19 / 16,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.mineTextPrimary,
              fontSize: 16.sp,
              height: 19 / 16,
            ),
          ),
        ],
      ),
    );
  }
}
