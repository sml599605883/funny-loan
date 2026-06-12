# Certification Work Info Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a standalone certification work-info page that follows the personal-info structure, uses the step-2 progress asset, and is entered through product-detail next-step routing.

**Architecture:** Keep the existing backend-driven certification flow intact by adding a new `CertificationWorkInfoPage` and routing normalized `job` to it through `NavigationHelper`. Reuse the current dynamic user-info schema, field models, bottom sheets, and submit contract instead of introducing a new API or generic form abstraction.

**Tech Stack:** Flutter, GetX routing, existing `ApiService`, widget tests with `flutter_test`

---

### Task 1: Add failing tests for work-info routing and page behavior

**Files:**
- Modify: `test/certification_step_page_test.dart`

- [ ] **Step 1: Write the failing route-handoff test**

```dart
testWidgets(
  'face page fetches product detail and dispatches work next step after submit success',
  (WidgetTester tester) async {
    Get.put<ApiService>(
      _FakeApiService(
        expectedProductId: '123',
        responseData: const <String, dynamic>{},
        productDetailResponseData: const <String, dynamic>{
          'gewurztraminers': 200,
          'reallot': '',
          'accretes': <String, dynamic>{
            'isolines': '123',
            'disprovable': 'Cash Loan',
            'rejectee': 'ORD-1',
          },
          'oocytes': <dynamic>[],
          'tetragrammaton': <String, dynamic>{
            'sidearms': 'work',
            'hazinesses': 'Work Information',
            'rutherfordiums': 'job',
            'outcrop': 0,
          },
        },
      ),
      permanent: true,
    );

    await tester.pumpWidget(_buildTestApp());

    Get.toNamed<dynamic>(
      AppRoutes.certificationFace,
      arguments: <String, dynamic>{
        'payload': <String, dynamic>{
          'nextStepTitle': 'Face verification',
          'productId': '123',
        },
      },
    );
    await tester.pump();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(CertificationWorkInfoPage), findsOneWidget);
    expect(find.text('Work Information'), findsOneWidget);
  },
);
```

- [ ] **Step 2: Run the focused route-handoff test to verify RED**

Run: `flutter test test/certification_step_page_test.dart --plain-name "face page fetches product detail and dispatches work info next step after submit success"`
Expected: FAIL because the current production `job` flow does not dispatch into a standalone work-info page yet.

### Task 2: Implement the standalone work-info page and route entry

**Files:**
- Create: `lib/app/modules/certification_step/views/certification_work_info_page.dart`
- Modify: `lib/app/routes/app_routes.dart`
- Modify: `lib/app/routes/app_pages.dart`
- Modify: `lib/app/routes/navigation_helper.dart`

- [ ] **Step 1: Add the new route constant**

```dart
static const certificationWorkInfo = '/certification-work-info';
```

- [ ] **Step 2: Register the new page in Get routes**

```dart
GetPage(
  name: AppRoutes.certificationWorkInfo,
  page: () => const CertificationWorkInfoPage(),
),
```

- [ ] **Step 3: Add a dedicated navigation helper**

```dart
static Future<T?>? toCertificationWorkInfo<T extends Object?>({
  Object? arguments,
}) {
  return Get.toNamed<T>(
    AppRoutes.certificationWorkInfo,
    arguments: _normalizeCertificationPayloadArguments(arguments),
  );
}
```

- [ ] **Step 4: Dispatch normalized `job` to the new page**

```dart
if (NavigationTargetMapper.normalizeProductDetailAuthItemCode(rawPage) == 'job') {
  return toCertificationWorkInfo<T>(arguments: arguments);
}
```

- [ ] **Step 5: Run the focused route-handoff test to verify GREEN**

Run: `flutter test test/certification_step_page_test.dart --plain-name "face page fetches product detail and dispatches work next step after submit success"`
Expected: PASS

### Task 3: Implement the work-info page using the existing dynamic form contract

**Files:**
- Create: `lib/app/modules/certification_step/views/certification_work_info_page.dart`
- Modify: `test/certification_step_page_test.dart`

- [ ] **Step 1: Write the failing render-and-submit test against the new route**

```dart
testWidgets('work info page submits edited values', (WidgetTester tester) async {
  final apiService = _FakeApiService(
    expectedProductId: '123',
    responseData: const <String, dynamic>{},
    userInfoResponseData: const <String, dynamic>{
      'rekeys': <String, dynamic>{
        'tingling': <Map<String, dynamic>>[
          <String, dynamic>{
            'hazinesses': 'Company Name',
            'tissual': 'Please enter',
            'unplait': 'interrogators',
            'dulses': 'Craniosacral',
            'dominances': 0,
            'scabiosa': <dynamic>[],
            'disrelished': 'Old Company',
          },
          <String, dynamic>{
            'hazinesses': 'City You Work',
            'tissual': 'Please select city',
            'unplait': 'picklocks',
            'dulses': 'RestroomInefficacies',
            'dominances': 0,
            'scabiosa': <dynamic>[],
            'disrelished': 'Province A-City A1-District A1A',
          },
          <String, dynamic>{
            'hazinesses': 'Type of Work',
            'tissual': 'Please select type',
            'unplait': 'placets',
            'dulses': 'Ataractics',
            'dominances': 0,
            'scabiosa': <Map<String, dynamic>>[
              <String, dynamic>{'governmental': 'Office Worker', 'outcrop': 1},
              <String, dynamic>{'governmental': 'Driver', 'outcrop': 2},
            ],
            'disrelished': '1',
          },
        ],
      },
    },
  );
  Get.put<ApiService>(apiService, permanent: true);
  String? fetchedProductId;

  await tester.pumpWidget(
    _buildTestApp(
      workInfoPageBuilder: () => CertificationWorkInfoPage(
        productDetailFlowRunner: (productId) async {
          fetchedProductId = productId;
        },
      ),
    ),
  );

  Get.toNamed<dynamic>(
    AppRoutes.certificationWorkInfo,
    arguments: <String, dynamic>{
      'payload': <String, dynamic>{
        'nextStepTitle': 'Work Information',
        'productId': '123',
      },
    },
  );
  await tester.pump();
  await tester.pumpAndSettle();

  await tester.enterText(
    find.byKey(const Key('certification_work_info_interrogators_input')),
    'New Company',
  );
  await tester.tap(
    find.byKey(const Key('certification_work_info_picklocks_selector')),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Province B'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Done'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('City B1').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Done'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('District B1A').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Done'));
  await tester.pumpAndSettle();
  await tester.tap(
    find.byKey(const Key('certification_work_info_placets_selector')),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Driver').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Done'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Submit'));
  await tester.pump();
  await tester.pumpAndSettle();

  expect(apiService.savedUserInfoBody, <String, dynamic>{
    'cohabiter': '123',
    'interrogators': 'New Company',
    'picklocks': 'Province B-City B1-District B1A',
    'placets': '2',
  });
  expect(fetchedProductId, '123');
});
```

- [ ] **Step 2: Run the focused test to verify RED**

Run: `flutter test test/certification_step_page_test.dart --plain-name "work info page submits edited values"`
Expected: FAIL because the work-info page, route, and work-info field widgets do not exist yet.

- [ ] **Step 3: Create the page by mirroring the personal-info flow with work-specific identifiers**

```dart
class CertificationWorkInfoPage extends StatefulWidget {
  const CertificationWorkInfoPage({
    super.key,
    this.apiService,
    this.productDetailFlowRunner =
        ApiNavigationHelper.fetchProductDetailByProductId,
  });

  final ApiService? apiService;
  final PersonalInfoProductDetailFlowRunner productDetailFlowRunner;
}
```

- [ ] **Step 4: Keep the same fetch/parse/submit contract**

```dart
Future<void> _loadUserInfo() async {
  final response = await _apiService.fetchUserInfo(<String, dynamic>{
    'cohabiter': productId,
  });
  final fields = _parseFields(response.raw);
  _replaceFields(fields);
}

Future<void> _submitUserInfo() async {
  final body = <String, dynamic>{'cohabiter': productId};
  for (final field in _fields) {
    body[field.saveKey] = field.currentSubmitValue;
  }
  await _apiService.saveUserInfo(body);
  await widget.productDetailFlowRunner(productId);
}
```

- [ ] **Step 5: Use the step-2 progress asset and work-info test keys**

```dart
Image.asset(
  'assets/certification/certification_personal_progress_step2.png',
  width: 343.w,
  fit: BoxFit.fitWidth,
)

key: Key('certification_work_info_${field.saveKey}_selector')
key: Key('certification_work_info_${field.saveKey}_input')
```

- [ ] **Step 6: Reuse the existing enum and address sheets without introducing new field models**

```dart
return EnumSelectionSheet(
  options: field.options,
  currentValue: field.currentSubmitValue,
);

return AddressSelectionSheet(
  title: field.label,
  options: addressOptions,
  currentValue: field.controller.text.trim(),
);
```

- [ ] **Step 7: Run the focused render-and-submit test to verify GREEN**

Run: `flutter test test/certification_step_page_test.dart --plain-name "work info page submits edited values"`
Expected: PASS

### Task 4: Wire the test harness and run the focused regression set

**Files:**
- Modify: `test/certification_step_page_test.dart`

- [ ] **Step 1: Extend the test app builder with the work-info route override**

```dart
Widget Function()? workInfoPageBuilder,

GetPage(
  name: AppRoutes.certificationWorkInfo,
  page: () =>
      workInfoPageBuilder?.call() ?? const CertificationWorkInfoPage(),
),
```

- [ ] **Step 2: Add a render assertion for the step-2 progress asset**

```dart
expect(
  find.byWidgetPredicate((widget) {
    return widget is Image &&
        widget.image is AssetImage &&
        (widget.image as AssetImage).assetName ==
            'assets/certification/certification_personal_progress_step2.png';
  }),
  findsOneWidget,
);
```

- [ ] **Step 3: Run the focused work-info tests**

Run: `flutter test test/certification_step_page_test.dart --plain-name "work info"`
Expected: PASS with all work-info tests green.

- [ ] **Step 4: Run the broader certification regression file**

Run: `flutter test test/certification_step_page_test.dart`
Expected: PASS with no certification regressions.

- [ ] **Step 5: Commit**

```bash
git add lib/app/modules/certification_step/views/certification_work_info_page.dart \
  lib/app/routes/app_routes.dart \
  lib/app/routes/app_pages.dart \
  lib/app/routes/navigation_helper.dart \
  test/certification_step_page_test.dart
git commit -m "feat: add certification work info step"
```
