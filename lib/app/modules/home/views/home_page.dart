import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';
import '../../../theme/screen_adapter.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
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
              children: [
                const _HomeHeader(),
                SizedBox(height: 16.h),
                const _TopHeroSection(),
                SizedBox(height: 16.h),
                const _BannerSection(),
                SizedBox(height: 16.h),
                const _OrderStatusSection(),
                SizedBox(height: 16.h),
                const _RecommendationSection(),
                SizedBox(height: 16.h),
                const _LoanProcessSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Hi！Welcome',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Image.asset(
          'assets/home/home_avatar_badge.png',
          width: 34.w,
          height: 34.w,
        ),
      ],
    );
  }
}

class _TopHeroSection extends StatelessWidget {
  const _TopHeroSection();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            image: const DecorationImage(
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
                child: const Text(
                  'App Name',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(height: 25.h),
              const Text(
                'Maximum Credit Amount',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                '₱ 60,000',
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
                    const Expanded(
                      child: _MetricTile(
                        icon: 'assets/home/home_status_icon_profile.png',
                        value: '91-180 Days',
                        label: 'Loan Term',
                      ),
                    ),
                    Container(width: 2.w, height: 35.h, color: Colors.white),
                    SizedBox(width: 10.w),
                    const Expanded(
                      child: _MetricTile(
                        icon: 'assets/home/home_status_icon_identity.png',
                        value: '< 0.05% / Day',
                        label: 'Low Interest',
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
                    'Apply Now',
                    style: TextStyle(
                      color: Color(0xFF3A57B0),
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

class _BannerSection extends StatelessWidget {
  const _BannerSection();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Image.asset(
        'assets/home/home_banner_bg.png',
        width: double.infinity,
        fit: BoxFit.fitWidth,
      ),
    );
  }
}

class _OrderStatusSection extends StatelessWidget {
  const _OrderStatusSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Order Status'),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFAABAB), width: 2),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFFFFFF), Color(0xFFFFC4C4)],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(13, 6, 13, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Past Due',
                      style: TextStyle(
                        color: Color(0xFFD05353),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Payment deadline has been missed',
                      style: TextStyle(color: Color(0xFFE87C7C), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: _OrderMetric(
                        value: '₱ 20,000',
                        label: 'Loan Amount',
                        emphasize: false,
                      ),
                    ),
                    Container(
                      width: 3,
                      height: 34,
                      color: const Color(0xFFFFEEEE),
                    ),
                    const SizedBox(width: 26),
                    const Expanded(
                      child: _OrderMetric(
                        value: '2026/05/13',
                        label: 'Due Date',
                        emphasize: true,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 2,
                margin: const EdgeInsets.only(top: 15),
                color: const Color(0xFFFAABAB),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 10, bottom: 12),
                child: Text(
                  'Repay',
                  style: TextStyle(
                    color: Color(0xFFD05353),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrderMetric extends StatelessWidget {
  const _OrderMetric({
    required this.value,
    required this.label,
    required this.emphasize,
  });

  final String value;
  final String label;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: emphasize ? const Color(0xFFD05353) : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 12),
        ),
      ],
    );
  }
}

class _RecommendationSection extends StatelessWidget {
  const _RecommendationSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Recommendation'),
        const _RecommendationCard(),
        const SizedBox(height: 10),
        const _RecommendationCard(),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFECEFFF), Color(0xFFCADFFD)],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 7),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A57B0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.apps_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'App Name',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A57B0),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 9,
                  ),
                  child: const Text(
                    'Apply Now',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₱ 20,000',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Available up to',
                        style: TextStyle(
                          color: Color(0xFFB0B0B0),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    _InfoTag(label: 'Interest rate：≤ 0.5% / Day'),
                    SizedBox(height: 5),
                    _InfoTag(label: 'Loan terms：180 Days'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1D6),
        borderRadius: BorderRadius.circular(9),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFFC6A86E), fontSize: 12),
      ),
    );
  }
}

class _LoanProcessSection extends StatelessWidget {
  const _LoanProcessSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Loan Process'),
        Image.asset(
          'assets/home/home_loan_process_bg.png',
          width: double.infinity,
          fit: BoxFit.fitWidth,
        ),
        SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.asset(
            'assets/home/home_bottom_bg.png',
            width: double.infinity,
            fit: BoxFit.fitWidth,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: ScreenAdapter.edgeInsetsOnly(top: 3, bottom: 10),
        child: Stack(
          children: [
            Positioned(
              top: 9.h,
              left: 0,
              right: 0,
              child: Container(
                height: 5.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8A2E),
                  borderRadius: BorderRadius.circular(5.r),
                ),
              ),
            ),
            Padding(
              padding: ScreenAdapter.edgeInsetsSymmetric(horizontal: 6),
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
