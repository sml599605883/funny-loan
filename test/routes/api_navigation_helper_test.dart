import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:funny_loan/app/core/json/json.dart';
import 'package:funny_loan/app/network/config/network_config.dart';
import 'package:funny_loan/app/routes/api_navigation_helper.dart';
import 'package:funny_loan/app/routes/navigation_target_mapper.dart';

void main() {
  group('ApiNavigationHelper', () {
    setUp(() {
      Get.reset();
      Get.put<MutableNetworkState>(
        MutableNetworkState(
          apiBaseUrl: 'http://47.80.83.200/l-funny',
          webBaseUrl: 'http://47.80.83.200',
        ),
      );
    });

    test('resolves recredit scheme to app page decision', () {
      final decision = ApiNavigationHelper.resolveDecision(
        Json(<String, dynamic>{
          'gewurztraminers': 302,
          'sidearms': 'gold://pocket/recredit',
          'outcrop': 0,
        }),
      );

      expect(decision['type'], ApiNavigationHelper.targetTypeAppPage);
      expect(
        decision['normalizedAppPage'],
        NavigationTargetMapper.recredit,
      );
      expect(decision['isNative'], isTrue);
    });

    test('resolves Unbosomed scheme with cohabiter to product detail page', () {
      final decision = ApiNavigationHelper.resolveDecision(
        Json(<String, dynamic>{
          'gewurztraminers': 302,
          'sidearms': 'ph://funny-loan/ios/Unbosomed?cohabiter=2',
          'outcrop': 0,
        }),
      );

      expect(decision['type'], ApiNavigationHelper.targetTypeAppPage);
      expect(
        decision['normalizedAppPage'],
        NavigationTargetMapper.productDetail,
      );
      expect(
        decision['rawTarget'],
        'ph://funny-loan/ios/Unbosomed?cohabiter=2',
      );
    });

    test('resolves http target to web url decision', () {
      final decision = ApiNavigationHelper.resolveDecision(
        Json(<String, dynamic>{
          'gewurztraminers': 505,
          'sidearms': 'http://example.com/#/errorUrl?productId=1',
          'outcrop': 1,
        }),
      );

      expect(decision['type'], ApiNavigationHelper.targetTypeWebUrl);
      expect(
        (decision['webUrl'] as Uri?)?.toString(),
        'http://example.com/#/errorUrl?productId=1',
      );
      expect(decision['isNative'], isFalse);
    });

    test('resolves relative h5 target with explicit web base url', () {
      final decision = ApiNavigationHelper.resolveDecision(
        Json(<String, dynamic>{
          'gewurztraminers': 302,
          'sidearms': '/#/ShowedJagger?productId=1',
          'outcrop': 1,
        }),
      );

      expect(decision['type'], ApiNavigationHelper.targetTypeWebUrl);
      expect(
        (decision['webUrl'] as Uri?)?.toString(),
        'http://47.80.83.200/#/ShowedJagger?productId=1',
      );
    });

    test('parses and normalizes product detail auth items and next step', () {
      final payload = ApiNavigationHelper.parseProductDetail(
        Json(<String, dynamic>{
          'accretes': <String, dynamic>{
            'isolines': '1',
            'disprovable': 'Super Prestamo',
            'rejectee': '302021063003045300522743',
          },
          'oocytes': <Map<String, dynamic>>[
            <String, dynamic>{
              'hazinesses': 'Informasi identitas',
              'rutherfordiums': 'public',
              'sidearms': '',
              'outcrop': 0,
              'fleshed': 1,
            },
            <String, dynamic>{
              'hazinesses': 'Living Recognition',
              'rutherfordiums': 'accumulators',
              'sidearms': '',
              'outcrop': 0,
              'fleshed': 1,
            },
          ],
          'tetragrammaton': <String, dynamic>{
            'rutherfordiums': 'PaterInstallers',
            'sidearms': '',
            'outcrop': 0,
            'hazinesses': 'Identifying information',
          },
          'scabiosa': <String, dynamic>{
            'beveling': 'identity top',
            'vicomtes': 'identity success top',
            'extricating': 'face top',
            'verves': 'personal top',
            'presumably': 'job top',
            'wolframite': 'contact top',
            'cytokinetic': 'bank top',
            'omitted': 'bank bottom',
          },
        }),
      );

      final authItems = payload['authItems'] as List<dynamic>;

      expect(payload['productId'], '1');
      expect(payload['productName'], 'Super Prestamo');
      expect(payload['orderNo'], '302021063003045300522743');
      expect(
        (authItems.first as Map<String, dynamic>)['routeKey'],
        'public',
      );
      expect(
        (authItems.last as Map<String, dynamic>)['routeKey'],
        'face',
      );
      expect(payload['nextStepCode'], '');
      expect(payload['nextStepTitle'], 'Identifying information');
      expect(
        payload['nextStepTarget'],
        'PaterInstallers',
      );
      expect(
        payload['scabiosa'],
        <String, String>{
          'beveling': 'identity top',
          'vicomtes': 'identity success top',
          'extricating': 'face top',
          'verves': 'personal top',
          'presumably': 'job top',
          'wolframite': 'contact top',
          'cytokinetic': 'bank top',
          'omitted': 'bank bottom',
        },
      );
      expect(
        ApiNavigationHelper.getCachedProductDetailScabiosa(),
        <String, String>{
          'beveling': 'identity top',
          'vicomtes': 'identity success top',
          'extricating': 'face top',
          'verves': 'personal top',
          'presumably': 'job top',
          'wolframite': 'contact top',
          'cytokinetic': 'bank top',
          'omitted': 'bank bottom',
        },
      );
    });
  });
}
