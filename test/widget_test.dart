import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:funny_loan/app/app.dart';
import 'package:funny_loan/app/core/storage/app_data_store.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    await AppDataStore.init();
  });

  setUp(() async {
    await AppDataStore.setPersistentString(AppDataStore.persistedTokenKey, '');
  });

  testWidgets(
    'main tab page shows fallback home content and three bottom tabs',
    (WidgetTester tester) async {
      await tester.pumpWidget(const FunnyLoanApp());
      await tester.pumpAndSettle();

      expect(find.text('Hi！Welcome'), findsOneWidget);
      expect(find.text('Loan Process'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(
        find.byWidgetPredicate((widget) {
          return widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  'assets/tabbar/tab_home_selected.png';
        }),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate((widget) {
          return widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  'assets/tabbar/tab_product_normal.png';
        }),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate((widget) {
          return widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  'assets/tabbar/tab_profile_normal.png';
        }),
        findsOneWidget,
      );
      await tester.pump(const Duration(milliseconds: 500));
    },
  );

  testWidgets('unauthenticated tab change opens login page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FunnyLoanApp());
    await tester.pumpAndSettle();

    await tester.tapAt(tester.getCenter(find.byType(BottomNavigationBar)));
    await tester.pumpAndSettle();

    expect(find.text('Get Code'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
  });
}
