# Certification Personal Info Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the third certification step as a standalone personal info page that fetches data from `fetchUserInfo`, saves through `saveUserInfo`, and keeps the header plus hint banner fixed while the lower content scrolls.

**Architecture:** Introduce a dedicated `CertificationPersonalInfoPage` under the existing certification-step views, register a new route/helper for it, and map the product-detail auth step code `personal` into that route. Reuse the current certification visual language but keep the page logic isolated from the first-step upload pages.

**Tech Stack:** Flutter, GetX routing, existing `ApiService`, widget tests with `flutter_test`

---

### Task 1: Personal info route and behavior tests

**Files:**
- Modify: `test/certification_step_page_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
testWidgets('personal info page renders independently', (tester) async {
  Get.put<ApiService>(_FakeApiService(expectedProductId: '123', responseData: const <String, dynamic>{}, userInfoResponseData: const <String, dynamic>{'governmental': 'Jane', 'rucking': '0999'}), permanent: true);
  await tester.pumpWidget(_buildTestApp());
  Get.toNamed<dynamic>(AppRoutes.certificationPersonalInfo, arguments: <String, dynamic>{'payload': <String, dynamic>{'nextStepTitle': 'Personal information', 'productId': '123'}});
  await tester.pump();
  await tester.pumpAndSettle();
  expect(find.text('Personal information'), findsOneWidget);
  expect(find.text('Jane'), findsOneWidget);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/certification_step_page_test.dart --plain-name "personal info page renders independently"`
Expected: FAIL because `AppRoutes.certificationPersonalInfo` and the page do not exist yet.

- [ ] **Step 3: Write minimal implementation**

```dart
static const certificationPersonalInfo = '/certification-personal-info';
GetPage(name: AppRoutes.certificationPersonalInfo, page: () => const CertificationPersonalInfoPage());
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/certification_step_page_test.dart --plain-name "personal info page renders independently"`
Expected: PASS

### Task 2: Save flow and route mapping

**Files:**
- Modify: `test/certification_step_page_test.dart`
- Modify: `lib/app/routes/navigation_helper.dart`
- Modify: `lib/app/routes/navigation_target_mapper.dart`
- Modify: `lib/app/modules/certification_step/views/certification_face_page.dart`

- [ ] **Step 1: Write the failing tests**

```dart
testWidgets('personal info page submits edited values', (tester) async {
  final apiService = _FakeApiService(expectedProductId: '123', responseData: const <String, dynamic>{}, userInfoResponseData: const <String, dynamic>{'governmental': 'Jane'});
  Get.put<ApiService>(apiService, permanent: true);
  await tester.pumpWidget(_buildTestApp());
  Get.toNamed<dynamic>(AppRoutes.certificationPersonalInfo, arguments: <String, dynamic>{'payload': <String, dynamic>{'nextStepTitle': 'Personal information', 'productId': '123'}});
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('certification_personal_info_full_name_input')), 'Mary');
  await tester.tap(find.text('Submit'));
  await tester.pumpAndSettle();
  expect(apiService.savedUserInfoBody?['governmental'], 'Mary');
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/certification_step_page_test.dart --plain-name "personal info page submits edited values"`
Expected: FAIL because the page has no form or save call yet.

- [ ] **Step 3: Write minimal implementation**

```dart
await _apiService.saveUserInfo(<String, dynamic>{'governmental': _fullNameController.text.trim()});
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/certification_step_page_test.dart --plain-name "personal info page submits edited values"`
Expected: PASS
