import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:funny_loan/app/app.dart';

void main() {
  testWidgets('main tab page shows home modules and three bottom tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const FunnyLoanApp());
    await tester.pumpAndSettle();

    expect(find.text('Hi！Welcome'), findsOneWidget);
    expect(find.text('Order Status'), findsOneWidget);
    expect(find.text('Recommendation'), findsOneWidget);
    expect(find.text('Loan Process'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.byWidgetPredicate((widget) {
      return widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName ==
              'assets/tabbar/tab_home_selected.png';
    }), findsOneWidget);
    expect(find.byWidgetPredicate((widget) {
      return widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName ==
              'assets/tabbar/tab_product_normal.png';
    }), findsOneWidget);
    expect(find.byWidgetPredicate((widget) {
      return widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName ==
              'assets/tabbar/tab_profile_normal.png';
    }), findsOneWidget);
  });

  testWidgets('detail page is opened by GetX route from product tab', (WidgetTester tester) async {
    await tester.pumpWidget(const FunnyLoanApp());
    await tester.pumpAndSettle();

    await tester.tapAt(tester.getCenter(find.byType(BottomNavigationBar)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('进入产品详情'));
    await tester.pumpAndSettle();

    expect(find.text('产品详情'), findsOneWidget);
  });
}
