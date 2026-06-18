import 'package:flutter_test/flutter_test.dart';
import 'package:funny_loan/app/core/json/json.dart';
import 'package:funny_loan/app/modules/home/models/home_popup_data.dart';

void main() {
  test('parses app upgrade popup fields', () {
    final data = HomePopupData.fromJson(
      Json(<String, dynamic>{
        'outcrop': 1,
        'fidelismo': <String, dynamic>{
          'hysterically': '1.2.3',
          'duchesses': 'Update content',
          'sidearms': 'https://example.test/update',
        },
      }),
    );

    expect(data.type, HomePopupType.appUpgrade);
    expect(data.shouldShow, isTrue);
    expect(data.displayVersion, 'V1.2.3');
    expect(data.content, 'Update content');
    expect(data.targetUrl, 'https://example.test/update');
  });

  test('parses marketing popup fields', () {
    final data = HomePopupData.fromJson(
      Json(<String, dynamic>{
        'outcrop': 3,
        'fidelismo': <String, dynamic>{
          'dizzyingly': 'https://example.test/popup.png',
          'sidearms': 'https://example.test/marketing',
        },
      }),
    );

    expect(data.type, HomePopupType.marketing);
    expect(data.shouldShow, isTrue);
    expect(data.imageUrl, 'https://example.test/popup.png');
    expect(data.targetUrl, 'https://example.test/marketing');
  });

  test('does not show unsupported popup types', () {
    for (final rawType in <int>[0, 2, 9]) {
      final data = HomePopupData.fromJson(
        Json(<String, dynamic>{
          'outcrop': rawType,
          'fidelismo': const <String, dynamic>{},
        }),
      );

      expect(data.shouldShow, isFalse);
    }
  });

  test('does not show marketing popup without image url', () {
    final data = HomePopupData.fromJson(
      Json(<String, dynamic>{
        'outcrop': 3,
        'fidelismo': const <String, dynamic>{'dizzyingly': ''},
      }),
    );

    expect(data.type, HomePopupType.marketing);
    expect(data.shouldShow, isFalse);
  });
}
