import 'package:flutter_test/flutter_test.dart';
import 'package:funny_loan/app/modules/card_list/models/card_list_data.dart';

void main() {
  test('parses keelboat sections and federalizes cells', () {
    final data = CardListData.fromJson(const <String, dynamic>{
      'unplait': 0,
      'gluteal': 'success',
      'rekeys': <String, dynamic>{
        'keelboat': <Map<String, dynamic>>[
          <String, dynamic>{
            'impotencies': 2,
            'intoxicated':
                'https://pera-agad-ios-files-prod.oss-ap-southeast-6.aliyuncs.com/other/icon_card_bank.png',
            'nemesis': 'Bank',
            'federalizes': <Map<String, dynamic>>[
              <String, dynamic>{
                'triaged': 1,
                'surly': '110',
                'mondos': 1,
                'euchromatic': '',
                'unappreciated': 'Banco Dipolog',
                'outcrop': 'BDI',
                'fleshed': 1,
                'cantilenas': '',
              },
            ],
          },
        ],
      },
    });

    expect(data.sections, hasLength(1));
    expect(data.sections.first.title, 'Bank');
    expect(data.sections.first.type, 2);
    expect(data.sections.first.iconUrl, contains('icon_card_bank.png'));
    expect(data.sections.first.cells, hasLength(1));

    final cell = data.sections.first.cells.first;
    expect(cell.type, 1);
    expect(cell.account, '110');
    expect(cell.isSelected, isTrue);
    expect(cell.logoUrl, isEmpty);
    expect(cell.name, 'Banco Dipolog');
    expect(cell.code, 'BDI');
    expect(cell.status, 1);
    expect(cell.tips, isEmpty);
  });
}
