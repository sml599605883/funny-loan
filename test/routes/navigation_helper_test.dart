import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:funny_loan/app/app.dart';
import 'package:funny_loan/app/core/storage/app_data_store.dart';
import 'package:funny_loan/app/routes/navigation_helper.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    await AppDataStore.init();
  });

  testWidgets('obfuscated app page can navigate to setting page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FunnyLoanApp());
    await tester.pumpAndSettle();

    NavigationHelper.toAppPage('MeshuggaDemised');
    await tester.pumpAndSettle();

    expect(find.text('Setting'), findsOneWidget);
  });

  testWidgets('obfuscated product detail page can navigate directly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FunnyLoanApp());
    await tester.pumpAndSettle();

    NavigationHelper.toAppPage('Unbosomed', arguments: '产品');
    await tester.pumpAndSettle();

    expect(find.text('产品详情'), findsOneWidget);
  });

  testWidgets('certification route key can navigate to certification step page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FunnyLoanApp());
    await tester.pumpAndSettle();

    NavigationHelper.toAppPage(
      'bank',
      arguments: <String, dynamic>{'nextStepTitle': 'Informasi bank'},
    );
    await tester.pumpAndSettle();

    expect(find.text('Informasi bank'), findsOneWidget);
  });

  testWidgets('face route key can navigate to certification face page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FunnyLoanApp());
    await tester.pumpAndSettle();

    NavigationHelper.toAppPage(
      'face',
      arguments: <String, dynamic>{'nextStepTitle': 'Face verification'},
    );
    await tester.pumpAndSettle();

    expect(find.text('Face verification'), findsOneWidget);
    expect(find.byKey(const Key('certification_face_demo_image')), findsOneWidget);
  });
}
