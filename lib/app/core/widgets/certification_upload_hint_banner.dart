import 'package:flutter/material.dart';

import '../storage/app_data_store.dart';
import '../../theme/app_colors.dart';
import '../../theme/screen_adapter.dart';

class CertificationUploadHintBanner extends StatelessWidget {
  const CertificationUploadHintBanner({
    super.key,
    this.scabiosaFieldKey,
    this.text = '',
  });

  final String? scabiosaFieldKey;
  final String text;
  final String badgeAssetPath =
      'assets/certification/certification_upload_badge.png';

  @override
  Widget build(BuildContext context) {
    final bannerText = _resolveBannerText();
    return Container(
      height: 58.h,
      margin: ScreenAdapter.edgeInsetsOnly(left: 20),
      child: Container(
        padding: ScreenAdapter.edgeInsetsOnly(left: 20, right: 16),
        decoration: BoxDecoration(
          color: AppColors.certificationHintSurface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            bottomLeft: Radius.circular(30),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Text(
                bannerText,
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
                style: TextStyle(
                  color: AppColors.certificationHintText,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(width: 17.w),
            Image.asset(
              badgeAssetPath,
              width: 60.w,
              height: 50.h,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }

  String _resolveBannerText() {
    final fieldKey = scabiosaFieldKey?.trim() ?? '';
    if (fieldKey.isEmpty) {
      return text;
    }
    final scabiosa = AppDataStore.getCache<Map<String, String>>(
      AppDataStore.productDetailScabiosaCacheKey,
    );
    final cachedText = scabiosa?[fieldKey]?.trim() ?? '';
    if (cachedText.isNotEmpty) {
      return cachedText;
    }
    return text;
  }
}
