import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/screen_adapter.dart';
import 'widgets/order_list_card.dart';
import 'widgets/order_list_header.dart';
import 'widgets/order_tab_bar.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  late int currentTabIndex;
  late final EasyRefreshController _refreshController;
  final List<_OrderListItem> _items = <_OrderListItem>[];
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    final arguments = Get.arguments;
    final initialTab = arguments is Map
        ? (arguments['initialTab'] as int? ?? 0)
        : 0;
    currentTabIndex = initialTab.clamp(0, OrderTabBar.labels.length - 1);
    _refreshController = EasyRefreshController(
      controlFinishRefresh: true,
      controlFinishLoad: true,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: ScreenAdapter.edgeInsetsOnly(
            left: 20,
            top: 16,
            right: 20,
            bottom: 24,
          ),
          child: Column(
            children: [
              const OrderListHeader(),
              SizedBox(height: 18.h),
              OrderTabBar(
                currentIndex: currentTabIndex,
                onChanged: _changeTab,
              ),
              SizedBox(height: 18.h),
              Expanded(
                child: EasyRefresh(
                  controller: _refreshController,
                  header: const ClassicHeader(
                    dragText: 'Pull down to refresh',
                    armedText: 'Release to refresh',
                    readyText: 'Refreshing...',
                    processingText: 'Refreshing...',
                    processedText: 'Refresh completed',
                    failedText: 'Refresh failed',
                    noMoreText: 'No more data',
                    messageText: 'Last updated at %T',
                  ),
                  footer: const ClassicFooter(
                    dragText: 'Pull up to load more',
                    armedText: 'Release to load',
                    readyText: 'Loading...',
                    processingText: 'Loading...',
                    processedText: 'Load completed',
                    failedText: 'Load failed',
                    noMoreText: 'No more orders',
                    messageText: 'Last updated at %T',
                  ),
                  onRefresh: _refreshOrders,
                  onLoad: _loadMore,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _items.length,
                    separatorBuilder: (context, index) =>
                        SizedBox(height: 10.h),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return OrderListCard(
                        status: item.status,
                        appName: item.appName,
                        amountText: item.amountText,
                        dueDateText: item.dueDateText,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  void _changeTab(int index) {
    if (index == currentTabIndex) {
      return;
    }
    setState(() {
      currentTabIndex = index;
    });
    _refreshOrders();
  }

  Future<void> _refreshOrders() async {
    if (_isRefreshing) {
      return;
    }
    setState(() {
      _isRefreshing = true;
    });
    _page = 1;
    _hasMore = true;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final refreshedItems = _buildPageItems(page: _page);
    if (!mounted) {
      return;
    }
    setState(() {
      _items
        ..clear()
        ..addAll(refreshedItems);
      _hasMore = _page < 3;
      _isRefreshing = false;
    });
    _refreshController.finishRefresh();
    _refreshController.resetFooter();
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isRefreshing) {
      return;
    }
    setState(() {
      _isLoadingMore = true;
    });
    final nextPage = _page + 1;
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final moreItems = _buildPageItems(page: nextPage);
    if (!mounted) {
      return;
    }
    setState(() {
      _page = nextPage;
      _items.addAll(moreItems);
      _hasMore = _page < 3;
      _isLoadingMore = false;
    });
    _refreshController.finishLoad(
      _hasMore ? IndicatorResult.success : IndicatorResult.noMore,
    );
  }

  List<_OrderListItem> _buildPageItems({required int page}) {
    final statuses = switch (currentTabIndex) {
      1 => const [OrderStatusType.outstanding, OrderStatusType.outstanding],
      2 => const [OrderStatusType.overdue, OrderStatusType.overdue],
      3 => const [OrderStatusType.settled, OrderStatusType.settled],
      _ => const [
          OrderStatusType.overdue,
          OrderStatusType.outstanding,
          OrderStatusType.settled,
          OrderStatusType.outstanding,
        ],
    };

    return List<_OrderListItem>.generate(statuses.length, (index) {
      final orderNumber = (page - 1) * statuses.length + index + 1;
      return _OrderListItem(
        status: statuses[index],
        appName: 'App Name',
        amountText: '₱ ${20 + orderNumber},000',
        dueDateText: '2026/05/${(12 + orderNumber).toString().padLeft(2, '0')}',
      );
    });
  }
}

class _OrderListItem {
  const _OrderListItem({
    required this.status,
    required this.appName,
    required this.amountText,
    required this.dueDateText,
  });

  final OrderStatusType status;
  final String appName;
  final String amountText;
  final String dueDateText;
}
