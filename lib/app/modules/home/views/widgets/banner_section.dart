import 'package:flutter/material.dart';

import '../../models/app_home_model.dart';

class BannerSection extends StatelessWidget {
  const BannerSection({super.key, required this.bannerList});

  final List<HomeBannerModel> bannerList;

  @override
  Widget build(BuildContext context) {
    final banner = bannerList.first;
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Image.network(
        banner.imageUrl,
        width: double.infinity,
        fit: BoxFit.fitWidth,
        errorBuilder: (_, error, stackTrace) {
          return Image.asset(
            'assets/home/home_banner_bg.png',
            width: double.infinity,
            fit: BoxFit.fitWidth,
          );
        },
      ),
    );
  }
}
