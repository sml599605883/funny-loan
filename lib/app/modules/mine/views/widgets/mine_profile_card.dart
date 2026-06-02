import 'package:flutter/material.dart';

import '../../../../core/storage/app_data_store.dart';
import '../../../../routes/navigation_helper.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/screen_adapter.dart';

class MineProfileCard extends StatelessWidget {
  const MineProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    final maskedPhone = _buildMaskedPhone();

    return Container(
      width: double.infinity,
      padding: ScreenAdapter.edgeInsetsOnly(
        left: 16,
        top: 21,
        right: 16,
        bottom: 19,
      ),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/mine/profile_card_bg.png'),
          fit: BoxFit.fill,
        ),
      ),
      child: Column(
        children: [
          Column(
            children: [
              Container(
                width: 81.r,
                height: 81.r,
                padding: ScreenAdapter.edgeInsetsOnly(
                  left: 4,
                  top: 4,
                  right: 5,
                  bottom: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.mineAvatarBackground,
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/mine/avatar_badge_bg.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                maskedPhone,
                style: TextStyle(
                  color: AppColors.mineTextSecondary,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 41.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _OrderEntry(
                assetPath: 'assets/mine/order_all.png',
                title: 'All order',
              ),
              _OrderEntry(
                assetPath: 'assets/mine/order_outstanding.png',
                title: 'Outstanding',
              ),
              _OrderEntry(
                assetPath: 'assets/mine/order_settled.png',
                title: 'Settled',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _buildMaskedPhone() {
    final phone =
        AppDataStore.getPersistentString(AppDataStore.persistedPhoneKey)
            ?.trim() ??
        '';
    if (phone.length < 7) {
      return phone;
    }
    final prefix = phone.substring(0, 3);
    final suffix = phone.substring(phone.length - 4);
    return '$prefix****$suffix';
  }
}

class _OrderEntry extends StatelessWidget {
  const _OrderEntry({required this.assetPath, required this.title});

  final String assetPath;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => NavigationHelper.toOrderList(
            initialTab: switch (title) {
              'All order' => 0,
              'Outstanding' => 1,
              'Settled' => 3,
              _ => 0,
            },
          ),
          child: Column(
            children: [
              Image.asset(
                assetPath,
                width: 56.w,
                height: 56.h,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 8.h),
              SizedBox(
                child: Text(
                  title,
                  style: TextStyle(color: Colors.black, fontSize: 14.sp),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
