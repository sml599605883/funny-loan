import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/screen_adapter.dart';
import '../../models/app_home_model.dart';
import 'section_title.dart';

class LoanProcessSection extends StatelessWidget {
  const LoanProcessSection({super.key, this.progressList = const []});

  final List<HomeProgressStepModel> progressList;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Loan Process'),
        if (progressList.isEmpty)
          Image.asset(
            'assets/home/home_loan_process_bg.png',
            width: double.infinity,
            fit: BoxFit.fitWidth,
          )
        else
          _ProgressLoanProcessCard(progressList: progressList),
        SizedBox(height: 10.h),
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

class _ProgressLoanProcessCard extends StatelessWidget {
  const _ProgressLoanProcessCard({required this.progressList});

  final List<HomeProgressStepModel> progressList;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.homeProcessSurface,
        borderRadius: BorderRadius.circular(20.r),
      ),
      padding: ScreenAdapter.edgeInsetsOnly(
        left: 12,
        top: 18,
        right: 12,
        bottom: 16,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(progressList.length, (index) {
              final step = progressList[index];
              return Expanded(
                child: _ProgressStepTile(
                  key: Key('loan_process_step_$index'),
                  step: step,
                  selected: step.isSelected == 1,
                ),
              );
            }),
          ),
          SizedBox(height: 14.h),
          _LoanProcessProgressBar(selectedRatio: _selectedProgressRatio),
        ],
      ),
    );
  }

  double get _selectedProgressRatio {
    final selectedIndex = progressList.lastIndexWhere(
      (step) => step.isSelected == 1,
    );
    if (selectedIndex < 0) {
      return 0;
    }
    if (progressList.length == 1) {
      return 0.5;
    }
    return (selectedIndex + 0.5) / progressList.length;
  }
}

class _LoanProcessProgressBar extends StatelessWidget {
  const _LoanProcessProgressBar({required this.selectedRatio});

  final double selectedRatio;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18.h,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final markerWidth = 19.w;
          final markerHeight = 18.h;
          final progressWidth = constraints.maxWidth * selectedRatio;
          final markerLeft = (progressWidth - markerWidth / 2).clamp(
            0.0,
            constraints.maxWidth - markerWidth,
          );

          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 6.h,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30.r),
                  child: SizedBox(
                    height: 6.h,
                    child: const ColoredBox(color: AppColors.homeProcessTrack),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 6.h,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30.r),
                  child: SizedBox(
                    width: progressWidth,
                    height: 6.h,
                    child: const ColoredBox(color: AppColors.homeAccent),
                  ),
                ),
              ),
              Positioned(
                left: markerLeft,
                top: 0,
                child: Image.asset(
                  'assets/recredit/recredit_progress_marker.png',
                  key: const Key('loan_process_progress_marker'),
                  width: markerWidth,
                  height: markerHeight,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProgressStepTile extends StatelessWidget {
  const _ProgressStepTile({
    super.key,
    required this.step,
    required this.selected,
  });

  final HomeProgressStepModel step;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 3.w),
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: selected ? AppColors.homeAccent : AppColors.homeProcessLocked,
        borderRadius: BorderRadius.circular(9.r),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            step.amount,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black,
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            step.title,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.homeProcessAmount,
              fontSize: 8.sp,
            ),
          ),
        ],
      ),
    );
  }
}
