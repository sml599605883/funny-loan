import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../network/api/api_service.dart';
import '../../../routes/api_navigation_helper.dart';
import '../../../theme/screen_adapter.dart';
import '../models/order_list_data.dart';
import '../utils/order_status_mapper.dart';
import 'widgets/order_list_card.dart';
import 'widgets/order_list_header.dart';
import 'widgets/order_tab_bar.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key, this.isVisible = true});

  final bool isVisible;

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  late int currentTabIndex;
  late final EasyRefreshController _refreshController;
  final List<OrderListItem> _items = <OrderListItem>[];
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  bool _isInitialLoading = true;
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
    if (widget.isVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshOrders();
      });
    }
  }

  @override
  void didUpdateWidget(covariant OrderListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isVisible && widget.isVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _refreshOrders();
      });
    }
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
              OrderTabBar(currentIndex: currentTabIndex, onChanged: _changeTab),
              SizedBox(height: 18.h),
              Expanded(
                child: EasyRefresh(
                  controller: _refreshController,
                  header: const ClassicHeader(
                    processedDuration: Duration.zero,
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
                  child: _buildOrderList(),
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _refreshController.callRefresh(force: true);
    });
  }

  Widget _buildOrderList() {
    if (_isInitialLoading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 120.h),
          Center(
            child: Text(
              'No orders',
              style: TextStyle(color: Colors.black54, fontSize: 14.sp),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _items.length,
      separatorBuilder: (context, index) => SizedBox(height: 10.h),
      itemBuilder: (context, index) {
        final item = _items[index];
        return OrderListCard(
          statusCode: item.statusCode,
          appName: item.productName,
          productLogo: item.productLogo,
          statusText: item.statusText,
          amountLabel: item.amountLabel,
          amountText: item.amountText,
          dueDateLabel: item.dateLabel,
          dueDateText: item.dateText,
          actionText: item.actionText,
          onTap: () => _handleOrderTap(item),
        );
      },
    );
  }

  Future<void> _handleOrderTap(OrderListItem item) async {
    final redirectUrl = item.redirectUrl.trim();
    if (redirectUrl.isNotEmpty) {
      await ApiNavigationHelper.navigateRawTarget(redirectUrl);
      return;
    }
    await ApiNavigationHelper.applyProductAndNavigate(item.productId);
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
    try {
      final refreshedItems = await _fetchOrders(page: _page);
      if (!mounted) {
        return;
      }
      setState(() {
        _items
          ..clear()
          ..addAll(refreshedItems);
        _hasMore = refreshedItems.isNotEmpty;
      });
      _refreshController.finishRefresh();
      _refreshController.resetFooter();
    } catch (_) {
      _refreshController.finishRefresh(IndicatorResult.fail);
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _isInitialLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isRefreshing) {
      return;
    }
    setState(() {
      _isLoadingMore = true;
    });
    final nextPage = _page + 1;
    try {
      final moreItems = await _fetchOrders(page: nextPage);
      if (!mounted) {
        return;
      }
      setState(() {
        _page = nextPage;
        _items.addAll(moreItems);
        _hasMore = moreItems.isNotEmpty;
      });
      _refreshController.finishLoad(
        _hasMore ? IndicatorResult.success : IndicatorResult.noMore,
      );
    } catch (_) {
      _refreshController.finishLoad(IndicatorResult.fail);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<List<OrderListItem>> _fetchOrders({required int page}) async {
    final response = await Get.find<ApiService>()
        .fetchOrderList(<String, dynamic>{
          'sulphide': OrderStatusMapper.statusCodeForTab(currentTabIndex),
          'carcase': '$page',
          'unawaked': '50',
        });
    return OrderListData.fromJson(response.data).items;
  }
}
