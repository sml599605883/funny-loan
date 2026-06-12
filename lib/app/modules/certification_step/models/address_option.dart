import '../../../core/json/json.dart';

import 'address_node.dart';

class AddressOption extends AddressNode {
  const AddressOption({
    required super.addressId,
    required super.label,
    required super.children,
  });

  static List<AddressOption> parseList(Json json) {
    final items = json['keelboat'].listValue;
    return items
        .map((item) => AddressOption.fromJson(Json(item)))
        .where((item) => item.label.isNotEmpty && item.children.isNotEmpty)
        .toList();
  }

  factory AddressOption.fromJson(Json json) {
    final node = AddressNode.fromJson(json);
    return AddressOption(
      label: node.label,
      children: node.children,
      addressId: node.addressId,
    );
  }
}
