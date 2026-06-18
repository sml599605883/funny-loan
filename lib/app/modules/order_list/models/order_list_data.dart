import '../../../core/json/json.dart';
import '../views/widgets/order_list_card.dart';

class OrderListData {
  const OrderListData({
    required this.items,
    required this.page,
    required this.hasMore,
  });

  final List<OrderListItem> items;
  final int page;
  final bool hasMore;

  factory OrderListData.fromJson(Json json) {
    final list = _listSource(json);
    final page = json['ebulliently'].intValue;
    return OrderListData(
      items: list
          .map((item) => OrderListItem.fromJson(Json(item)))
          .where((item) => item.orderNo.isNotEmpty)
          .toList(),
      page: page,
      hasMore: list.isNotEmpty,
    );
  }

  static List<dynamic> _listSource(Json json) {
    if (json.listValue.isNotEmpty) {
      return json.listValue;
    }
    for (final key in const ['keelboat', 'list', 'items']) {
      final list = json[key].listValue;
      if (list.isNotEmpty) {
        return list;
      }
    }
    return const <dynamic>[];
  }
}

class OrderListItem {
  const OrderListItem({
    required this.orderId,
    required this.orderNo,
    required this.productId,
    required this.productName,
    required this.productLogo,
    required this.status,
    required this.statusText,
    required this.amountText,
    required this.amountLabel,
    required this.actionText,
    required this.redirectUrl,
    required this.dateLabel,
    required this.dateText,
    required this.overdueDays,
  });

  final int orderId;
  final String orderNo;
  final String productId;
  final String productName;
  final String productLogo;
  final OrderStatusType status;
  final String statusText;
  final String amountText;
  final String amountLabel;
  final String actionText;
  final String redirectUrl;
  final String dateLabel;
  final String dateText;
  final int overdueDays;

  factory OrderListItem.fromJson(Json json) {
    return OrderListItem(
      orderId: json['marlstone'].intValue,
      orderNo: json['rejectee'].stringValue.trim(),
      productId: json['skoals'].stringValue.trim(),
      productName: json['disprovable'].stringValue.trim(),
      productLogo: json['subsider'].stringValue.trim(),
      status: _statusFromCode(json['qwertys'].intValue),
      statusText: json['sugar'].stringValue.trim(),
      amountText: json['unfindable'].stringValue.trim(),
      amountLabel: json['marchionesses'].stringValue.trim(),
      actionText: json['overengineered'].stringValue.trim(),
      redirectUrl: json['estrangement'].stringValue.trim(),
      dateLabel: json['knights'].stringValue.trim(),
      dateText: json['hiccuped'].stringValue.trim(),
      overdueDays: json['bidi'].intValue,
    );
  }

  static OrderStatusType _statusFromCode(int code) {
    switch (code) {
      case 5:
        return OrderStatusType.settled;
      case 6:
        return OrderStatusType.overdue;
      case 7:
      default:
        return OrderStatusType.outstanding;
    }
  }
}
