import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/app_home_model.dart';

class BannerSection extends StatefulWidget {
  const BannerSection({super.key, required this.bannerList, this.onBannerTap});

  final List<HomeBannerModel> bannerList;
  final ValueChanged<HomeBannerModel>? onBannerTap;

  @override
  State<BannerSection> createState() => _BannerSectionState();
}

class _BannerSectionState extends State<BannerSection> {
  static const Duration _autoPlayInterval = Duration(seconds: 3);
  static const Duration _pageAnimationDuration = Duration(milliseconds: 350);
  static const double _bannerAspectRatio = 1005 / 291;

  late final PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentVirtualPage = 0;

  List<HomeBannerModel> get _bannerList => widget.bannerList;

  @override
  void initState() {
    super.initState();
    _currentVirtualPage = _initialPage;
    _pageController = PageController(initialPage: _currentVirtualPage);
    _startAutoPlayIfNeeded();
  }

  @override
  void didUpdateWidget(covariant BannerSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bannerList.length != widget.bannerList.length) {
      _stopAutoPlay();
      final nextPage = _initialPage;
      _currentVirtualPage = nextPage;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(nextPage);
      }
      _startAutoPlayIfNeeded();
      return;
    }

    if (!_shouldAutoPlay) {
      _stopAutoPlay();
    } else if (_autoPlayTimer == null) {
      _startAutoPlayIfNeeded();
    }
  }

  @override
  void dispose() {
    _stopAutoPlay();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_bannerList.isEmpty) {
      return const SizedBox.shrink();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: _bannerAspectRatio,
        child: PageView.builder(
          controller: _pageController,
          itemBuilder: (context, index) {
            final banner = _bannerAt(index);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onBannerTap == null
                  ? null
                  : () => widget.onBannerTap?.call(banner),
              child: Image.network(
                banner.imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, error, stackTrace) {
                  return Image.asset(
                    'assets/home/home_banner_bg.png',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  );
                },
              ),
            );
          },
          onPageChanged: (index) => _currentVirtualPage = index,
        ),
      ),
    );
  }

  int get _initialPage {
    if (!_shouldAutoPlay) {
      return 0;
    }
    return _bannerList.length * 1000;
  }

  bool get _shouldAutoPlay => _bannerList.length > 1;

  HomeBannerModel _bannerAt(int virtualIndex) {
    return _bannerList[virtualIndex % _bannerList.length];
  }

  void _startAutoPlayIfNeeded() {
    if (!_shouldAutoPlay) {
      return;
    }
    _autoPlayTimer = Timer.periodic(_autoPlayInterval, (_) {
      if (!mounted || !_pageController.hasClients) {
        return;
      }
      _pageController.animateToPage(
        _currentVirtualPage + 1,
        duration: _pageAnimationDuration,
        curve: Curves.easeInOut,
      );
    });
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
  }
}
