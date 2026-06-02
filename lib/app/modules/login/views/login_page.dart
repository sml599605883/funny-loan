import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../routes/navigation_helper.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/screen_adapter.dart';
import '../controllers/login_controller.dart';

class LoginPage extends GetView<LoginController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentHeight = math.max(constraints.maxHeight, 812.h);
            final viewInsets = MediaQuery.of(context).viewInsets.bottom;

            return AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.only(bottom: viewInsets),
              child: AutofillGroup(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: SizedBox(
                    height: contentHeight,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 20.w,
                          top: 17.h,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => NavigationHelper.back<void>(),
                            child: Padding(
                              padding: ScreenAdapter.edgeInsetsOnly(
                                right: 12,
                                bottom: 12,
                              ),
                              child: Image.asset(
                                'assets/login/icon_login_back.png',
                                width: 25.w,
                                height: 26.h,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 20.w,
                          right: 20.w,
                          top: 101.h,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _LoginCard(controller: controller),
                              SizedBox(height: 21.h),
                              Padding(
                                padding: ScreenAdapter.edgeInsetsOnly(
                                  left: 0,
                                  right: 1,
                                ),
                                child: _AgreementSection(
                                  controller: controller,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: ScreenAdapter.edgeInsetsSymmetric(
            horizontal: 20,
            vertical: 16,
          ),
          child: Image.asset(
            'assets/home/home_bottom_bg.png',
            fit: BoxFit.fitWidth,
          ),
        ),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({required this.controller});

  final LoginController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final buttonColor = controller.canSubmit.value
          ? AppColors.loginPrimary
          : AppColors.loginButtonDisabled;
      final isRequestCodeEnabled =
          controller.canRequestCode.value &&
          controller.countdown.value == 0 &&
          !controller.isRequestingCode.value;

      return Container(
        padding: ScreenAdapter.edgeInsetsOnly(left: 26, right: 26, bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: const [
            BoxShadow(
              color: AppColors.loginCardShadow,
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
          image: const DecorationImage(
            image: AssetImage('assets/login/bg_login_card_header.png'),
            fit: BoxFit.fill,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: ScreenAdapter.edgeInsetsOnly(top: 32),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/login/img_login_avatar_placeholder.png',
                    width: 56.w,
                    height: 56.w,
                  ),
                  SizedBox(width: 17.w),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Hi',
                          style: TextStyle(
                            color: AppColors.loginPrimary,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: '!',
                          style: TextStyle(
                            color: AppColors.loginPrimary,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: 'Welcome',
                          style: TextStyle(
                            color: AppColors.loginPrimary,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 53.h),
            _LoginField(
              leading: const Text(
                '+',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              secondaryLeading: const Padding(
                padding: EdgeInsets.only(left: 3),
                child: Text(
                  '63',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              controller: controller.phoneController,
              focusNode: controller.phoneFocusNode,
              hintText: 'Please fill in your phone number',
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(15),
              ],
              autofillHints: const [AutofillHints.telephoneNumberNational],
              keyboardType: TextInputType.number,
              textStyle: TextStyle(
                color: Colors.black,
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 19.h),
            _LoginField(
              controller: controller.codeController,
              focusNode: controller.codeFocusNode,
              hintText: 'Send SMS verification code',
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              autofillHints: const [AutofillHints.oneTimeCode],
              keyboardType: TextInputType.number,
              textStyle: TextStyle(
                color: Colors.black,
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
              trailing: GestureDetector(
                onTap: isRequestCodeEnabled ? controller.requestCode : null,
                behavior: HitTestBehavior.opaque,
                child: Text(
                  controller.countdown.value > 0
                      ? '${controller.countdown.value}s'
                      : 'Get Code',
                  style: TextStyle(
                    color: controller.countdown.value > 0
                        ? AppColors.loginCountdown
                        : (isRequestCodeEnabled
                              ? Colors.black
                              : AppColors.loginPlaceholder),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SizedBox(height: 40.h),
            GestureDetector(
              onTap: controller.canSubmit.value ? controller.submit : null,
              child: Container(
                width: double.infinity,
                height: 50.h,
                padding: ScreenAdapter.edgeInsetsSymmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: buttonColor,
                  borderRadius: BorderRadius.circular(25.r),
                ),
                child: Text(
                  "Let's Go",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    this.leading,
    this.secondaryLeading,
    required this.controller,
    this.focusNode,
    required this.hintText,
    this.trailing,
    this.inputFormatters,
    this.keyboardType,
    this.textStyle,
    this.autofillHints,
  });

  final Widget? leading;
  final Widget? secondaryLeading;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final Widget? trailing;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType? keyboardType;
  final TextStyle? textStyle;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    final prefixChildren = <Widget>[];
    if (leading != null) {
      prefixChildren.add(leading!);
    }
    if (secondaryLeading != null) {
      prefixChildren.add(secondaryLeading!);
    }

    return Container(
      padding: ScreenAdapter.edgeInsetsOnly(
        left: 12,
        top: 16,
        right: 12,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
      ),
      height: 54.h,
      child: Row(
        children: [
          ...prefixChildren,
          if (prefixChildren.isNotEmpty) ...[
            SizedBox(width: 10.w),
            Container(
              width: 1.w,
              height: 21.h,
              color: AppColors.loginInputDivider,
            ),
            SizedBox(width: 10.w),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              inputFormatters: inputFormatters,
              keyboardType: keyboardType,
              autofillHints: autofillHints,
              enableSuggestions: false,
              autocorrect: false,
              style: textStyle,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: TextStyle(
                  color: AppColors.loginPlaceholder,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: 12.w),
            Container(
              width: 1.w,
              height: 21.h,
              color: AppColors.loginInputDivider,
            ),
            SizedBox(width: 10.w),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _AgreementSection extends StatelessWidget {
  const _AgreementSection({required this.controller});

  final LoginController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Padding(
        padding: ScreenAdapter.edgeInsetsSymmetric(horizontal: 17),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: controller.toggleAgreement,
              child: Padding(
                padding: ScreenAdapter.edgeInsetsOnly(top: 3, right: 8),
                child: Image.asset(
                  controller.agreed.value
                      ? 'assets/login/icon_login_checked.png'
                      : 'assets/login/icon_login_unchecked.png',
                  width: 16.w,
                  height: 16.w,
                ),
              ),
            ),
            Expanded(
              child: Wrap(
                children: [
                  Text(
                    'I have read and agree to the ',
                    style: TextStyle(color: Colors.white, fontSize: 14.sp),
                  ),
                  GestureDetector(
                    onTap: controller.onPrivacyPolicyTap,
                    child: Text(
                      'Privacy Policy',
                      style: TextStyle(
                        color: AppColors.loginPolicyHighlight,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.loginPolicyHighlight,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
