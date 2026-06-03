import 'package:flutter_test/flutter_test.dart';

import 'package:funny_loan/app/routes/app_routes.dart';
import 'package:funny_loan/app/routes/navigation_target_mapper.dart';

void main() {
  group('NavigationTargetMapper', () {
    test('normalizes app pages from canonical and obfuscated values', () {
      expect(
        NavigationTargetMapper.normalizeAppPage('main'),
        NavigationTargetMapper.main,
      );
      expect(
        NavigationTargetMapper.normalizeAppPage('Ruinousnesses'),
        NavigationTargetMapper.main,
      );
      expect(
        NavigationTargetMapper.normalizeAppPage('MeshuggaDemised'),
        NavigationTargetMapper.setting,
      );
      expect(
        NavigationTargetMapper.normalizeAppPage('Unbosomed'),
        NavigationTargetMapper.productDetail,
      );
    });

    test('maps app pages to current GetX routes', () {
      expect(
        NavigationTargetMapper.routeForAppPage('Ruinousnesses'),
        AppRoutes.home,
      );
      expect(
        NavigationTargetMapper.routeForAppPage('MeshuggaDemised'),
        AppRoutes.setting,
      );
      expect(
        NavigationTargetMapper.routeForAppPage('Anthranilate'),
        AppRoutes.orderList,
      );
      expect(
        NavigationTargetMapper.routeForAppPage('Unbosomed'),
        AppRoutes.detail,
      );
    });

    test('extracts app page from direct value and scheme target', () {
      expect(
        NavigationTargetMapper.appPageFromTarget('MeshuggaDemised'),
        NavigationTargetMapper.setting,
      );
      expect(
        NavigationTargetMapper.appPageFromTarget('gold://pocket/recredit'),
        NavigationTargetMapper.recredit,
      );
    });

    test('maps order status code to tab index', () {
      expect(NavigationTargetMapper.orderTabIndexForCode('4'), 0);
      expect(NavigationTargetMapper.orderTabIndexForCode('7'), 1);
      expect(NavigationTargetMapper.orderTabIndexForCode('6'), 2);
      expect(NavigationTargetMapper.orderTabIndexForCode('5'), 3);
    });

    test('normalizes product detail auth item codes', () {
      expect(
        NavigationTargetMapper.normalizeProductDetailAuthItemCode(
          'governmental',
        ),
        'name',
      );
      expect(
        NavigationTargetMapper.normalizeProductDetailAuthItemCode('accumulators'),
        'face',
      );
      expect(
        NavigationTargetMapper.normalizeProductDetailAuthItemCode(
          'vaporousnesses',
        ),
        'company_address_detail',
      );
      expect(
        NavigationTargetMapper.normalizeProductDetailAuthItemCode('bank'),
        'bank',
      );
    });
  });
}
