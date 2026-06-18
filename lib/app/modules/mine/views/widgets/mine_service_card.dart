import 'package:flutter/material.dart';

import '../../../../core/utils/web_page_opener.dart';
import '../../../../routes/navigation_helper.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/screen_adapter.dart';

class MineServiceCard extends StatelessWidget {
  const MineServiceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: ScreenAdapter.edgeInsetsOnly(
            left: 12,
            top: 12,
            right: 12,
            bottom: 12,
          ),
          decoration: BoxDecoration(
            color: AppColors.mineServiceCard,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            children: [
              _ServiceTile(
                iconPath: 'assets/mine/service_online.png',
                title: 'Online Services',
                onTap: () =>
                    WebPageOpener.openPath('/#/SuperhighwaySubscribes'),
              ),
              const _TileGap(),
              _ServiceTile(
                iconPath: 'assets/mine/service_settings.png',
                title: 'Setting',
                onTap: NavigationHelper.toSetting,
              ),
              const _TileGap(),
              _ServiceTile(
                iconPath: 'assets/mine/service_privacy.png',
                title: 'Privacy Agreement',
                onTap: () => WebPageOpener.openPath('/#/Portmanteaus'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.iconPath, required this.title, this.onTap});

  final String iconPath;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: ScreenAdapter.edgeInsetsOnly(
          left: 12,
          top: 13,
          right: 12,
          bottom: 14,
        ),
        decoration: BoxDecoration(
          color: AppColors.mineServiceTile,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          children: [
            Image.asset(
              iconPath,
              width: 21.w,
              height: 18.h,
              fit: BoxFit.contain,
            ),
            SizedBox(width: 13.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppColors.mineTextPrimary,
                  fontSize: 16.sp,
                  height: 19 / 16,
                ),
              ),
            ),
            Image.asset(
              'assets/mine/chevron_right.png',
              width: 14.w,
              height: 15.h,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}

class _TileGap extends StatelessWidget {
  const _TileGap();

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 12.h);
  }
}
