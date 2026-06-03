import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/screen_adapter.dart';
import '../controllers/home_controller.dart';
import '../models/app_home_model.dart';
import 'widgets/banner_section.dart';
import 'widgets/home_header.dart';
import 'widgets/loan_process_section.dart';
import 'widgets/order_status_section.dart';
import 'widgets/recommendation_section.dart';
import 'widgets/top_hero_section.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final homeData = controller.homeResponse.value;
      final productList = homeData?.productList ?? const <HomeProductModel>[];
      final processList = homeData?.processList ?? const <HomeProcessModel>[];
      final bannerList = homeData?.bannerList ?? const <HomeBannerModel>[];

      final children = <Widget>[const HomeHeader()];

      if (homeData?.largeCard != null) {
        children.add(SizedBox(height: 16.h));
        children.add(
          TopHeroSection(
            card: homeData!.largeCard!,
            onTap: () => controller.applyTopHeroProduct(homeData.largeCard!),
          ),
        );
      }
      if (bannerList.isNotEmpty) {
        children.add(SizedBox(height: 16.h));
        children.add(BannerSection(bannerList: bannerList));
      }
      if (processList.isNotEmpty) {
        children.add(SizedBox(height: 16.h));
        children.add(OrderStatusSection(processList: processList));
      }
      if (productList.isNotEmpty) {
        children.add(SizedBox(height: 16.h));
        children.add(RecommendationSection(productList: productList));
      }
      if (processList.isEmpty && productList.isEmpty) {
        children.add(SizedBox(height: 16.h));
        children.add(const LoanProcessSection());
      }

      return Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: controller.fetchHomeData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: ScreenAdapter.edgeInsetsOnly(
                left: 20.w,
                top: 18.w,
                right: 20.w,
                bottom: 35.w,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),
        ),
      );
    });
  }
}
