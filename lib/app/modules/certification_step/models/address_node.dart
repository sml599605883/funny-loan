import '../../../core/json/json.dart';

class AddressNode {
  const AddressNode({
    required this.addressId,
    required this.label,
    required this.children,
  });

  final String addressId;
  final String label;
  final List<AddressNode> children;

  factory AddressNode.fromJson(Json json) {
    return AddressNode(
      addressId: json['isolines'].stringValue.trim(),
      label: json['governmental'].stringValue.trim(),
      children: json['keelboat'].listValue
          .map((item) => AddressNode.fromJson(Json(item)))
          .where((item) => item.label.isNotEmpty)
          .toList(),
    );
  }
}
