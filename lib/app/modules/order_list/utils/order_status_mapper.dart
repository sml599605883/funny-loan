class OrderStatusMapper {
  const OrderStatusMapper._();

  static String statusCodeForTab(int index) {
    return switch (index) {
      1 => '7',
      2 => '6',
      3 => '5',
      _ => '4',
    };
  }
}
