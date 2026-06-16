import '../../../core/json/json.dart';

class CardListData {
  const CardListData({required this.sections});

  factory CardListData.fromJson(Object? raw) {
    final json = Json(raw);
    final source = json['rekeys']['keelboat'].listValue.isNotEmpty
        ? json['rekeys']['keelboat']
        : json['keelboat'];
    return CardListData(
      sections: source.listValue
          .map((item) => CardListSection.fromJson(Json(item)))
          .where(
            (section) => section.title.isNotEmpty && section.cells.isNotEmpty,
          )
          .toList(),
    );
  }

  final List<CardListSection> sections;
}

class CardListSection {
  const CardListSection({
    required this.type,
    required this.iconUrl,
    required this.title,
    required this.cells,
  });

  factory CardListSection.fromJson(Json json) {
    return CardListSection(
      type: json['impotencies'].intValue,
      iconUrl: json['intoxicated'].stringValue.trim(),
      title: json['nemesis'].stringValue.trim(),
      cells: json['federalizes'].listValue
          .map((item) => CardListCell.fromJson(Json(item)))
          .where((cell) => cell.name.isNotEmpty)
          .toList(),
    );
  }

  final int type;
  final String iconUrl;
  final String title;
  final List<CardListCell> cells;
}

class CardListCell {
  const CardListCell({
    required this.type,
    required this.account,
    required this.isSelected,
    required this.logoUrl,
    required this.name,
    required this.code,
    required this.status,
    required this.tips,
  });

  factory CardListCell.fromJson(Json json) {
    return CardListCell(
      type: json['triaged'].intValue,
      account: json['surly'].stringValue.trim(),
      isSelected: json['mondos'].intValue == 1,
      logoUrl: json['euchromatic'].stringValue.trim(),
      name: json['unappreciated'].stringValue.trim(),
      code: json['outcrop'].stringValue.trim(),
      status: json['fleshed'].intValue,
      tips: json['cantilenas'].stringValue.trim(),
    );
  }

  final int type;
  final String account;
  final bool isSelected;
  final String logoUrl;
  final String name;
  final String code;
  final int status;
  final String tips;
}
