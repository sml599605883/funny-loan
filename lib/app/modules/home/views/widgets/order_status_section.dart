import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../models/app_home_model.dart';
import 'section_title.dart';

typedef OrderStatusButtonTap =
    void Function(HomeProcessModel process, HomeProcessButtonModel button);

class OrderStatusSection extends StatefulWidget {
  const OrderStatusSection({
    super.key,
    required this.processList,
    this.onProcessTap,
    this.onButtonTap,
  });

  final List<HomeProcessModel> processList;
  final ValueChanged<HomeProcessModel>? onProcessTap;
  final OrderStatusButtonTap? onButtonTap;

  @override
  State<OrderStatusSection> createState() => _OrderStatusSectionState();
}

class _OrderStatusSectionState extends State<OrderStatusSection> {
  static const Duration _autoPlayInterval = Duration(seconds: 3);
  static const Duration _pageAnimationDuration = Duration(milliseconds: 350);

  late final PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentVirtualPage = 0;

  List<HomeProcessModel> get _processList => widget.processList;

  @override
  void initState() {
    super.initState();
    _currentVirtualPage = _initialPage;
    _pageController = PageController(initialPage: _currentVirtualPage);
    _startAutoPlayIfNeeded();
  }

  @override
  void didUpdateWidget(covariant OrderStatusSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.processList.length != widget.processList.length) {
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
    if (_processList.isEmpty) {
      return const SizedBox.shrink();
    }
    final pageHeight = _resolvePageHeight(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Order Status'),
        SizedBox(
          height: pageHeight,
          child: PageView.builder(
            controller: _pageController,
            itemBuilder: (context, index) {
              final process = _processAt(index);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onProcessTap == null
                    ? null
                    : () => widget.onProcessTap?.call(process),
                child: _OrderStatusCard(
                  process: process,
                  onProcessTap: widget.onProcessTap,
                  onButtonTap: widget.onButtonTap,
                ),
              );
            },
            onPageChanged: (index) => _currentVirtualPage = index,
          ),
        ),
      ],
    );
  }

  int get _initialPage {
    if (!_shouldAutoPlay) {
      return 0;
    }
    return _processList.length * 1000;
  }

  bool get _shouldAutoPlay => _processList.length > 1;

  HomeProcessModel _processAt(int virtualIndex) {
    return _processList[virtualIndex % _processList.length];
  }

  double _resolvePageHeight(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return 161 + (textScale - 1).clamp(0, 1) * 40;
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

class _OrderStatusCard extends StatelessWidget {
  const _OrderStatusCard({
    required this.process,
    this.onProcessTap,
    this.onButtonTap,
  });

  final HomeProcessModel process;
  final ValueChanged<HomeProcessModel>? onProcessTap;
  final OrderStatusButtonTap? onButtonTap;

  @override
  Widget build(BuildContext context) {
    final style = _OrderStatusCardStyle.resolve(process.cardStatus);
    final actions = _actionTexts(process);

    return Container(
      key: const ValueKey<String>('order_status_card'),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: style.borderColor, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            key: const ValueKey<String>('order_status_header'),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: style.headerGradient,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(13, 6, 13, 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  process.orderStatusText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: style.titleColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 18 / 14,
                  ),
                ),
                Text(
                  process.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: style.descriptionColor,
                    fontSize: 12,
                    height: 18 / 12,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(41, 16, 32, 0),
            child: Row(
              children: [
                _OrderMetric(
                  value: process.displayAmount.isNotEmpty
                      ? process.displayAmount
                      : process.amount,
                  label: process.amountDesc,
                  emphasize: false,
                ),
                Container(
                  width: 3,
                  height: 34,
                  margin: const EdgeInsets.only(left: 42),
                  color: style.metricDividerColor,
                ),
                const SizedBox(width: 33),
                _OrderMetric(
                  value: process.date,
                  label: process.dateDesc,
                  emphasize: style.emphasizeDate,
                  emphasizeColor: style.titleColor,
                ),
              ],
            ),
          ),
          Container(
            height: 2,
            margin: const EdgeInsets.only(top: 15),
            color: style.borderColor,
          ),
          Expanded(
            child: _OrderStatusActions(
              actions: actions,
              style: style,
              onProcessTap: onProcessTap == null
                  ? null
                  : () => onProcessTap?.call(process),
              onButtonTap: (button) => onButtonTap?.call(process, button),
            ),
          ),
        ],
      ),
    );
  }

  List<_OrderStatusAction> _actionTexts(HomeProcessModel process) {
    final visibleActions = process.buttons
        .where((button) => button.enabled == 1 && button.text.trim().isNotEmpty)
        .map((button) => _OrderStatusAction.button(button))
        .toList();

    if (visibleActions.isNotEmpty) {
      return visibleActions;
    }
    return const <_OrderStatusAction>[_OrderStatusAction.details()];
  }
}

class _OrderStatusActions extends StatelessWidget {
  const _OrderStatusActions({
    required this.actions,
    required this.style,
    this.onProcessTap,
    this.onButtonTap,
  });

  final List<_OrderStatusAction> actions;
  final _OrderStatusCardStyle style;
  final VoidCallback? onProcessTap;
  final ValueChanged<HomeProcessButtonModel>? onButtonTap;

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      color: style.actionColor,
      fontSize: actions.length > 1 ? 14 : 16,
      fontWeight: FontWeight.w700,
      height: 18 / (actions.length > 1 ? 14 : 16),
    );

    if (actions.length == 1) {
      final action = actions.first;
      return Center(
        child: _OrderStatusActionButton(
          text: action.text,
          style: textStyle,
          onTap: _tapForAction(action),
        ),
      );
    }

    return Row(
      children: [
        for (var index = 0; index < actions.length; index++) ...[
          Expanded(
            child: Center(
              child: _OrderStatusActionButton(
                text: actions[index].text,
                style: textStyle.copyWith(
                  color: index == 0 && style.useAlternateFirstActionColor
                      ? AppColors.homeOrderStatusButtonOrange
                      : style.actionColor,
                ),
                onTap: _tapForAction(actions[index]),
              ),
            ),
          ),
          if (index != actions.length - 1)
            Container(
              width: 2,
              height: double.infinity,
              color: style.borderColor,
            ),
        ],
      ],
    );
  }

  VoidCallback? _tapForAction(_OrderStatusAction action) {
    if (action.isDetails || action.isRepay) {
      return onProcessTap;
    }
    if (action.button != null &&
        (action.normalizedAction == 'retry' ||
            action.normalizedAction == 'change')) {
      return () => onButtonTap?.call(action.button!);
    }
    return null;
  }
}

class _OrderStatusAction {
  const _OrderStatusAction._({required this.text, this.button});

  const _OrderStatusAction.details() : this._(text: 'Details');

  factory _OrderStatusAction.button(HomeProcessButtonModel button) {
    return _OrderStatusAction._(text: button.text.trim(), button: button);
  }

  final String text;
  final HomeProcessButtonModel? button;

  bool get isDetails => button == null && text == 'Details';

  bool get isRepay => normalizedAction == 'repay';

  String get normalizedAction => button?.action.trim().toLowerCase() ?? '';
}

class _OrderStatusActionButton extends StatelessWidget {
  const _OrderStatusActionButton({
    required this.text,
    required this.style,
    required this.onTap,
  });

  final String text;
  final TextStyle style;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
      ),
    );
  }
}

class _OrderMetric extends StatelessWidget {
  const _OrderMetric({
    required this.value,
    required this.label,
    required this.emphasize,
    this.emphasizeColor = AppColors.homeOrderStatusRedTitle,
  });

  final String value;
  final String label;
  final bool emphasize;
  final Color emphasizeColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: emphasize ? emphasizeColor : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            height: 24 / 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.orderLabelText,
            fontSize: 12,
            height: 14 / 12,
          ),
        ),
      ],
    );
  }
}

class _OrderStatusCardStyle {
  const _OrderStatusCardStyle({
    required this.borderColor,
    required this.headerGradient,
    required this.titleColor,
    required this.descriptionColor,
    required this.metricDividerColor,
    required this.actionColor,
    this.emphasizeDate = false,
    this.useAlternateFirstActionColor = false,
  });

  final Color borderColor;
  final List<Color> headerGradient;
  final Color titleColor;
  final Color descriptionColor;
  final Color metricDividerColor;
  final Color actionColor;
  final bool emphasizeDate;
  final bool useAlternateFirstActionColor;

  static const _OrderStatusCardStyle blue = _OrderStatusCardStyle(
    borderColor: AppColors.homeOrderStatusBlueBorder,
    headerGradient: <Color>[
      AppColors.homeOrderStatusBlueHeaderStart,
      AppColors.homeOrderStatusBlueHeaderEnd,
    ],
    titleColor: AppColors.homeOrderStatusBlueTitle,
    descriptionColor: AppColors.homeOrderStatusBlueDescription,
    metricDividerColor: AppColors.homeOrderStatusBlueBorder,
    actionColor: Colors.black,
  );

  static const _OrderStatusCardStyle red = _OrderStatusCardStyle(
    borderColor: AppColors.homeOrderStatusRedBorder,
    headerGradient: <Color>[
      AppColors.homeOrderStatusRedHeaderStart,
      AppColors.homeOrderStatusRedHeaderEnd,
    ],
    titleColor: AppColors.homeOrderStatusRedTitle,
    descriptionColor: AppColors.homeOrderStatusRedDescription,
    metricDividerColor: AppColors.homeOrderStatusRedDividerLight,
    actionColor: AppColors.homeOrderStatusRedTitle,
  );

  static const _OrderStatusCardStyle overdue = _OrderStatusCardStyle(
    borderColor: AppColors.homeOrderStatusRedBorder,
    headerGradient: <Color>[
      AppColors.homeOrderStatusRedHeaderStart,
      AppColors.homeOrderStatusRedHeaderEnd,
    ],
    titleColor: AppColors.homeOrderStatusRedTitle,
    descriptionColor: AppColors.homeOrderStatusRedDescription,
    metricDividerColor: AppColors.homeOrderStatusRedDividerLight,
    actionColor: AppColors.homeOrderStatusRedTitle,
    emphasizeDate: true,
  );

  static const _OrderStatusCardStyle fundingFailedWithRetry =
      _OrderStatusCardStyle(
        borderColor: AppColors.homeOrderStatusRedBorder,
        headerGradient: <Color>[
          AppColors.homeOrderStatusRedHeaderStart,
          AppColors.homeOrderStatusRedHeaderEnd,
        ],
        titleColor: AppColors.homeOrderStatusRedTitle,
        descriptionColor: AppColors.homeOrderStatusRedDescription,
        metricDividerColor: AppColors.homeOrderStatusRedDividerLight,
        actionColor: AppColors.homeOrderStatusRedTitle,
        useAlternateFirstActionColor: true,
      );

  static _OrderStatusCardStyle resolve(int cardStatus) {
    switch (cardStatus) {
      case 1:
      case 4:
        return blue;
      case 3:
        return overdue;
      case 6:
        return fundingFailedWithRetry;
      case 2:
      case 5:
      default:
        return red;
    }
  }
}
