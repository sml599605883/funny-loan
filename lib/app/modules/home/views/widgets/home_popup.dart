import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../routes/navigation_helper.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/screen_adapter.dart';
import '../../models/home_popup_data.dart';

typedef HomePopupExternalOpener = Future<bool> Function(Uri uri);
typedef HomePopupInAppOpener = void Function(String url);

class HomePopup {
  HomePopup._();

  static const upgradeButtonKey = Key('home_popup_upgrade_button');
  static const marketingImageKey = Key('home_popup_marketing_image');
  static const upgradeBackgroundAsset =
      'assets/setting/setting_upgrade_popup_bg.png';

  static Future<bool> show(
    HomePopupData data, {
    HomePopupExternalOpener? externalOpener,
    HomePopupInAppOpener? inAppOpener,
  }) async {
    if (!data.shouldShow) {
      return false;
    }

    await Get.dialog<void>(
      data.type == HomePopupType.appUpgrade
          ? UpgradePopupContent(data: data, externalOpener: externalOpener)
          : MarketingPopupContent(data: data, inAppOpener: inAppOpener),
      barrierColor: AppColors.settingDialogBarrier,
      barrierDismissible: true,
      transitionDuration: Duration.zero,
    );
    return true;
  }
}

class UpgradePopupContent extends StatelessWidget {
  const UpgradePopupContent({
    super.key,
    required this.data,
    this.externalOpener,
  });

  final HomePopupData data;
  final HomePopupExternalOpener? externalOpener;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final dialogWidth = math.min(305.w, screenSize.width - 70.w);

    return Center(
      child: Container(
        width: dialogWidth,
        height: dialogWidth * (312.0 / 305.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.r),
          image: const DecorationImage(
            image: AssetImage(HomePopup.upgradeBackgroundAsset),
            fit: BoxFit.fill,
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 95.w),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Text(
                'New version released',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.settingDialogTitle,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  height: 22 / 16,
                ),
              ),
            ),
            SizedBox(height: 14.w),
            if (data.displayVersion.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.w),
                child: Text(
                  data.displayVersion,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.certificationUploadDialogText,
                    fontSize: 16.sp,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w700,
                    height: 20 / 16,
                  ),
                ),
              ),
            SizedBox(height: 6.w),
            SizedBox(
              height: 60.h,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.w),
                child: Text(
                  data.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.certificationUploadDialogText,
                    fontSize: 16.sp,
                    height: 20 / 16,
                  ),
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.only(left: 58.w, right: 57.w, bottom: 17.w),
              child: GestureDetector(
                key: HomePopup.upgradeButtonKey,
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    _openTarget(data.targetUrl, externalOpener: externalOpener),
                child: Container(
                  height: 48.h,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.loginPrimary,
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  child: Text(
                    'Update Now',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.mineServiceCard,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      height: 22 / 18,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MarketingPopupContent extends StatelessWidget {
  const MarketingPopupContent({
    super.key,
    required this.data,
    this.inAppOpener,
  });

  final HomePopupData data;
  final HomePopupInAppOpener? inAppOpener;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final width = screenSize.width - 48.w;
    final maxHeight = screenSize.height - 96.h;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          child: GestureDetector(
            key: HomePopup.marketingImageKey,
            behavior: HitTestBehavior.opaque,
            onTap: () => _openInAppTarget(data.targetUrl, inAppOpener),
            child: Image.network(
              data.imageUrl,
              width: width,
              fit: BoxFit.fitWidth,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _openTarget(
  String rawUrl, {
  HomePopupExternalOpener? externalOpener,
}) async {
  final url = rawUrl.trim();
  if (url.isEmpty) {
    return;
  }
  Get.back<void>();
  final uri = Uri.tryParse(url);
  if (uri == null) {
    return;
  }
  await (externalOpener ?? _launchExternal).call(uri);
}

Future<bool> _launchExternal(Uri uri) {
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

void _openInAppTarget(String rawUrl, HomePopupInAppOpener? inAppOpener) {
  final url = rawUrl.trim();
  if (url.isEmpty) {
    return;
  }
  Get.back<void>();
  (inAppOpener ?? NavigationHelper.toWebView).call(url);
}
