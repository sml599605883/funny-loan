import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/app_home_model.dart';
import 'section_title.dart';

class OrderStatusSection extends StatefulWidget {
  const OrderStatusSection({
    super.key,
    required this.processList,
    this.onProcessTap,
  });

  final List<HomeProcessModel> processList;
  final ValueChanged<HomeProcessModel>? onProcessTap;

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
                child: _OrderStatusCard(process: process),
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
    return 188 + (textScale - 1).clamp(0, 1) * 40;
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
  const _OrderStatusCard({required this.process});

  final HomeProcessModel process;

  @override
  Widget build(BuildContext context) {
    final actionText = process.buttons.isNotEmpty
        ? process.buttons.first.text
        : process.orderStatusText;

    return Container(
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
              children: [
                Text(
                  process.orderStatusText,
                  style: const TextStyle(
                    color: Color(0xFFD05353),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  process.title,
                  style: const TextStyle(
                    color: Color(0xFFE87C7C),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
            child: Row(
              children: [
                Expanded(
                  child: _OrderMetric(
                    value: process.displayAmount.isNotEmpty
                        ? process.displayAmount
                        : process.amount,
                    label: process.amountDesc,
                    emphasize: false,
                  ),
                ),
                Container(width: 3, height: 34, color: const Color(0xFFFFEEEE)),
                const SizedBox(width: 26),
                Expanded(
                  child: _OrderMetric(
                    value: process.date,
                    label: process.dateDesc,
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
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 12),
            child: Text(
              actionText,
              style: const TextStyle(
                color: Color(0xFFD05353),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
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
