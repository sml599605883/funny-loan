import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/recredit_polling_coordinator.dart';
import '../../../routes/navigation_helper.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/screen_adapter.dart';

typedef RecreditProgressDelayGenerator = Duration Function();
typedef RecreditProgressIncrementGenerator = int Function(int currentProgress);

class RecreditPage extends StatefulWidget {
  const RecreditPage({
    super.key,
    this.progressDelayGenerator,
    this.progressIncrementGenerator,
  });

  final RecreditProgressDelayGenerator? progressDelayGenerator;
  final RecreditProgressIncrementGenerator? progressIncrementGenerator;

  @override
  State<RecreditPage> createState() => _RecreditPageState();
}

class _RecreditPageState extends State<RecreditPage> {
  final Random _random = Random();
  Timer? _progressTimer;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _scheduleNextProgressTick();
    _startRecreditPollingTask();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ScreenAdapter.init(context);
    final mediaQuery = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: AppColors.recreditBackground,
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            SizedBox(height: 48.h),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: ScreenAdapter.edgeInsetsOnly(left: 16),
                child: _RecreditBackButton(
                  onTap: () => NavigationHelper.back<void>(),
                ),
              ),
            ),
            SizedBox(height: 92.h),
            Padding(
              padding: ScreenAdapter.edgeInsetsSymmetric(horizontal: 75),
              child: Image.asset(
                'assets/recredit/recredit_illustration.png',
                key: const Key('recredit_illustration'),
                width: double.infinity,
                height: (mediaQuery.size.width - 150.w) * (175.0 / 226.0),
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 17.h),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      color: AppColors.recreditTextPrimary,
                      fontSize: 12.sp,
                      fontFamily: 'Helvetica',
                      fontWeight: FontWeight.w400,
                      height: 18 / 12,
                    ),
                    children: const [
                      TextSpan(text: 'Calculating your credit limit, just '),
                      TextSpan(
                        text: '30 seconds',
                        style: TextStyle(
                          color: AppColors.recreditHighlight,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Please wait patiently',
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.recreditTextPrimary,
                    fontSize: 12.sp,
                    fontFamily: 'Helvetica',
                    fontWeight: FontWeight.w400,
                    height: 18 / 12,
                  ),
                ),
              ],
            ),
            SizedBox(height: 33.h),
            _RecreditProgressSection(progress: _progress),
          ],
        ),
      ),
    );
  }

  void _scheduleNextProgressTick() {
    if (_progress >= 99) {
      return;
    }
    _progressTimer?.cancel();
    _progressTimer = Timer(_nextProgressDelay(), _advanceProgress);
  }

  void _advanceProgress() {
    if (!mounted || _progress >= 99) {
      return;
    }
    final nextProgress = (_progress + _nextProgressIncrement()).clamp(0, 99);
    setState(() => _progress = nextProgress);
    _scheduleNextProgressTick();
  }

  Duration _nextProgressDelay() {
    final generator = widget.progressDelayGenerator;
    if (generator != null) {
      return generator();
    }
    return Duration(seconds: 1 + _random.nextInt(3));
  }

  int _nextProgressIncrement() {
    final generator = widget.progressIncrementGenerator;
    if (generator != null) {
      return generator(_progress);
    }
    return 5 + _random.nextInt(11);
  }

  void _startRecreditPollingTask() {
    final productId = _productIdFromArguments(Get.arguments);
    if (productId.isEmpty) {
      return;
    }
    if (!Get.isRegistered<RecreditPollingCoordinator>()) {
      Get.put<RecreditPollingCoordinator>(
        RecreditPollingCoordinator(),
        permanent: true,
      );
    }
    Get.find<RecreditPollingCoordinator>().start(productId: productId);
  }

  String _productIdFromArguments(Object? arguments) {
    if (arguments is! Map) {
      return '';
    }
    final mapped = Map<String, dynamic>.from(arguments);
    final payload = mapped['payload'];
    if (payload is Map) {
      final payloadMap = Map<String, dynamic>.from(payload);
      return ((payloadMap['productId'] ?? payloadMap['cohabiter']) as String? ??
              '')
          .trim();
    }
    return ((mapped['productId'] ?? mapped['cohabiter']) as String? ?? '')
        .trim();
  }
}

class _RecreditProgressSection extends StatelessWidget {
  const _RecreditProgressSection({required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 305.w,
      height: 58.h,
      child: _RecreditProgressBar(progress: progress),
    );
  }
}

class _RecreditProgressBar extends StatelessWidget {
  const _RecreditProgressBar({required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) {
    final progressWidth = 305.w * (progress / 100);
    final markerLeft = (progressWidth - 9.5.w).clamp(0.0, 286.w);
    final labelLeft = (progressWidth - 25.5.w).clamp(0.0, 254.w);
    return SizedBox(
      width: 305.w,
      height: 47.h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            key: const Key('recredit_progress_bar'),
            left: 0,
            top: 6.h,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: SizedBox(
                width: 305.w,
                height: 7.h,
                child: const ColoredBox(color: AppColors.recreditProgressTrack),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 6.h,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: SizedBox(
                width: progressWidth,
                height: 7.h,
                child: const ColoredBox(color: AppColors.recreditProgressValue),
              ),
            ),
          ),
          Positioned(
            left: markerLeft,
            top: 0,
            child: Image.asset(
              'assets/recredit/recredit_progress_marker.png',
              key: const Key('recredit_status_icon'),
              width: 19.w,
              height: 18.h,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            left: labelLeft,
            top: 24.h,
            child: _RecreditProgressLabel(progress: progress),
          ),
        ],
      ),
    );
  }
}

class _RecreditBackButton extends StatelessWidget {
  const _RecreditBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('recredit_return_button'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 44.w,
        height: 44.h,
        child: Center(
          child: Image.asset(
            'assets/icon_back.png',
            width: 25.w,
            height: 25.w,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _RecreditProgressLabel extends StatelessWidget {
  const _RecreditProgressLabel({required this.progress});

  final int progress;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('recredit_progress_label_container'),
      decoration: BoxDecoration(
        color: AppColors.recreditProgressLabel,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: SizedBox(
        width: 51.w,
        height: 24.h,
        child: Center(
          child: Text(
            '$progress%',
            key: const Key('recredit_progress_label'),
            style: TextStyle(
              color: AppColors.recreditButtonText,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              height: 17 / 12,
            ),
          ),
        ),
      ),
    );
  }
}

class RecreditDesignSpecPreview extends StatelessWidget {
  const RecreditDesignSpecPreview({super.key});

  @override
  Widget build(BuildContext context) {
    ScreenAdapter.init(context);
    return const SizedBox(width: 375, height: 812, child: RecreditPage());
  }
}
