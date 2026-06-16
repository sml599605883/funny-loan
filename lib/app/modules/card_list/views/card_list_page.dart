import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

import '../../../core/json/json.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../network/api/api_service.dart';
import '../../../network/errors/network_error_mapper.dart';
import '../../../routes/navigation_helper.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/screen_adapter.dart';
import '../../home/views/widgets/section_title.dart';
import '../models/card_list_data.dart';

class CardListPage extends StatefulWidget {
  const CardListPage({super.key});

  @override
  State<CardListPage> createState() => _CardListPageState();
}

class _CardListPageState extends State<CardListPage> {
  late final _CardListPageArgs _pageArgs = _CardListPageArgs.from(
    Get.arguments,
  );
  late final CardListData _cardListData = CardListData.fromJson(
    <String, dynamic>{'keelboat': _pageArgs.keelboat},
  );
  late String _selectedCellId = _resolveInitialSelectedCellId();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.certificationUploadBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AppPageHeader(title: 'Loan Application'),
            Expanded(
              child: SingleChildScrollView(
                padding: ScreenAdapter.edgeInsetsOnly(
                  left: 20,
                  right: 20,
                  bottom: 24,
                ),
                child: Column(
                  children: [
                    for (final section in _cardListData.sections) ...[
                      SectionTitle(
                        title: section.title,
                        titleColor: Colors.black,
                      ),
                      for (final cell in section.cells) ...[
                        _PaymentMethodCard(
                          item: cell,
                          isSelected: _selectedCellId == cell.account,
                          onTap: () {
                            setState(() {
                              _selectedCellId = cell.account;
                            });
                          },
                        ),
                      ],
                      SizedBox(height: 32.h),
                    ],
                    _AddPaymentMethodCard(onTap: _openAddPaymentMethod),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _CardListFooter(
        onTap: _isSubmitting ? null : _openBindCard,
      ),
    );
  }

  void _openAddPaymentMethod() {
    NavigationHelper.toCertificationBindCard(
      routeKey: 'bank',
      arguments: <String, dynamic>{
        'payload': <String, dynamic>{
          'productId': _pageArgs.productId,
          'orderNo': _pageArgs.orderNo,
          'ischange': _pageArgs.isChange,
        },
      },
    );
  }

  Future<void> _openBindCard() async {
    final selectedCell = _selectedCell;
    if (selectedCell == null) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      EasyLoading.show();
      final response = await Get.find<ApiService>().changeBankCard(
        <String, dynamic>{
          'nosh': _pageArgs.orderNo,
          'triaged': selectedCell.type,
        },
      );
      final redirectUrl = response.data['copybooks'].stringValue.trim();
      if (redirectUrl.isEmpty) {
        return;
      }
      EasyLoading.dismiss();
      NavigationHelper.toWebView(redirectUrl);
    } catch (error) {
      EasyLoading.showError(NetworkErrorMapper.map(error));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  CardListCell? get _selectedCell {
    for (final section in _cardListData.sections) {
      for (final cell in section.cells) {
        if (cell.account == _selectedCellId) {
          return cell;
        }
      }
    }
    return null;
  }

  String _resolveInitialSelectedCellId() {
    for (final section in _cardListData.sections) {
      for (final cell in section.cells) {
        if (cell.isSelected) {
          return cell.account;
        }
      }
    }
    return '';
  }
}

class _CardListPageArgs {
  const _CardListPageArgs({
    required this.productId,
    required this.orderNo,
    required this.isChange,
    required this.keelboat,
  });

  factory _CardListPageArgs.from(Object? arguments) {
    final routeArguments = arguments is Map
        ? Map<String, dynamic>.from(arguments)
        : const <String, dynamic>{};
    return _CardListPageArgs(
      productId: (routeArguments['productId'] as String? ?? '').trim(),
      orderNo: (routeArguments['orderNo'] as String? ?? '').trim(),
      isChange: Json(routeArguments['ischange']).boolValue,
      keelboat: Json(
        routeArguments['keelboat'],
      ).listValue.map((item) => Json(item).mapValue).toList(),
    );
  }

  final String productId;
  final String orderNo;
  final bool isChange;
  final List<Map<String, dynamic>> keelboat;
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final CardListCell item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardListSectionCard,
          borderRadius: BorderRadius.circular(20.r),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 60.h,
              color: AppColors.cardListSectionHeader,
              padding: ScreenAdapter.edgeInsetsSymmetric(horizontal: 16),
              child: Row(
                children: [
                  _PaymentLogoView(item: item),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Text(
                      item.name,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        height: 24 / 20,
                      ),
                    ),
                  ),
                  _SelectionIndicator(isSelected: isSelected),
                ],
              ),
            ),
            Padding(
              padding: ScreenAdapter.edgeInsetsOnly(
                left: 15,
                top: 10,
                right: 15,
                bottom: 13,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: ScreenAdapter.edgeInsetsOnly(
                      left: 15,
                      top: 10,
                      right: 15,
                      bottom: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardListAccountSurface,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Receipt Account',
                          style: TextStyle(
                            color: AppColors.cardListAccountLabel,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: 7.h),
                        Text(
                          item.account,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item.tips.isNotEmpty) ...[
                    SizedBox(height: 9.h),
                    Center(
                      child: Text(
                        item.tips,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.cardListWarningText,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      isSelected
          ? 'assets/cardList/icon_selected.png'
          : 'assets/cardList/icon_selected_alt.png',
      width: 20.w,
      height: 20.h,
      fit: BoxFit.contain,
    );
  }
}

class _AddPaymentMethodCard extends StatelessWidget {
  const _AddPaymentMethodCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: const Color.fromARGB(255, 164, 164, 164),
          radius: 16.r,
        ),
        child: Container(
          width: double.infinity,
          padding: ScreenAdapter.edgeInsetsSymmetric(
            horizontal: 18,
            vertical: 28,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/cardList/icon_add_payment.png',
                width: 30.w,
                height: 30.h,
                fit: BoxFit.contain,
              ),
              SizedBox(width: 15.w),
              Text(
                'Add other payment methods',
                style: TextStyle(
                  color: AppColors.cardListMutedText,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w400,
                  height: 20 / 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardListFooter extends StatelessWidget {
  const _CardListFooter({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.certificationUploadBackground,
      padding: ScreenAdapter.edgeInsetsOnly(
        left: 56,
        top: 12,
        right: 56,
        bottom: 34,
      ),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            height: 50.h,
            decoration: BoxDecoration(
              color: AppColors.certificationUploadSuccessButton,
              borderRadius: BorderRadius.circular(25.r),
            ),
            alignment: Alignment.center,
            child: Text(
              'Submit',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                height: 22 / 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentLogoView extends StatelessWidget {
  const _PaymentLogoView({required this.item});

  final CardListCell item;

  @override
  Widget build(BuildContext context) {
    if (item.logoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Image.network(
          item.logoUrl,
          width: 30.w,
          height: 30.h,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _FallbackLogo(code: item.code),
        ),
      );
    }

    return _FallbackLogo(code: item.code);
  }
}

class _FallbackLogo extends StatelessWidget {
  const _FallbackLogo({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30.w,
      height: 30.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      alignment: Alignment.center,
      child: Text(
        code.isNotEmpty ? code : '?',
        style: TextStyle(
          color: AppColors.cardListBdoBlue,
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final path = Path()..addRRect(rect);

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
