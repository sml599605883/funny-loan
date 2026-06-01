import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:funny_loan/app/core/json/json.dart';

void main() {
  group('Json helper', () {
    test('parses string and supports chained reads', () {
      final json = Json.parse('{"user":{"name":"alice","age":"18"}}');

      expect(json['user']['name'].stringValue, 'alice');
      expect(json['user']['age'].intValue, 18);
      expect(json['missing']['field'].stringValue, '');
      expect(json['missing']['field'].stringOrNull, isNull);
    });

    test('parses bytes safely and degrades on invalid input', () {
      final valid = Json.parseBytes(utf8.encode('{"flag":1}'));
      final invalid = Json.parse('{bad json}');

      expect(valid['flag'].boolValue, isTrue);
      expect(invalid.isNull(), isTrue);
      expect(invalid.mapValue, isEmpty);
    });

    test('converts scalar values with safe defaults', () {
      expect(Json('yes').boolValue, isTrue);
      expect(Json('0').boolValue, isFalse);
      expect(Json(true).numValue, 1);
      expect(Json('12.5').doubleValue, 12.5);
      expect(Json(3).stringValue, '3');
      expect(Json(<String, dynamic>{}).stringValue, '');
    });
  });
}
