import 'dart:math' as math;

import 'package:flutter/widgets.dart';

class ScreenAdapter {
  ScreenAdapter._();

  static const Size designSize = Size(375, 812);

  static late double _scaleWidth;
  static late double _scaleHeight;
  static late double _scaleText;
  static bool _initialized = false;

  static void init(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    _scaleWidth = mediaQuery.size.width / designSize.width;
    _scaleHeight = mediaQuery.size.height / designSize.height;
    _scaleText = math.min(_scaleWidth, _scaleHeight);
    _initialized = true;
  }

  static double w(num value) {
    _assertInitialized();
    return value * _scaleWidth;
  }

  static double h(num value) {
    _assertInitialized();
    return value * _scaleHeight;
  }

  static double r(num value) {
    _assertInitialized();
    return value * math.min(_scaleWidth, _scaleHeight);
  }

  static double sp(num value) {
    _assertInitialized();
    return value * _scaleText;
  }

  static EdgeInsets edgeInsetsOnly({
    num left = 0,
    num top = 0,
    num right = 0,
    num bottom = 0,
  }) {
    return EdgeInsets.only(
      left: w(left),
      top: h(top),
      right: w(right),
      bottom: h(bottom),
    );
  }

  static EdgeInsets edgeInsetsSymmetric({
    num horizontal = 0,
    num vertical = 0,
  }) {
    return EdgeInsets.symmetric(
      horizontal: w(horizontal),
      vertical: h(vertical),
    );
  }

  static void _assertInitialized() {
    assert(
      _initialized,
      'ScreenAdapter.init(context) must be called before using ScreenAdapter.',
    );
  }
}

extension ScreenAdapterNumExt on num {
  double get w => ScreenAdapter.w(this);
  double get h => ScreenAdapter.h(this);
  double get r => ScreenAdapter.r(this);
  double get sp => ScreenAdapter.sp(this);
}
