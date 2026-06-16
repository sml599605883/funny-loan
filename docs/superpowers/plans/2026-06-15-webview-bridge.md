# Funny Loan WebView Bridge Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a Funny Loan WebView page and H5 bridge that route actions through current app capabilities.

**Architecture:** Keep the WebView page thin and move all action handling into a dispatcher. Reuse existing navigation, API, and native bridge code paths wherever possible so the H5 contract stays isolated from UI details.

**Tech Stack:** Flutter, GetX, `url_launcher`, existing Funny Loan networking/routing/native modules, WebView package already present or added to the app.

---

### Task 1: Add failing tests for the new WebView bridge contract

**Files:**
- Create: `test/webview/webview_bridge_dispatcher_test.dart`
- Modify: `test/routes/api_navigation_helper_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
testWidgets('dispatches openUrl through current app url handling', (tester) async {
  // arrange a fake dispatcher target and expect the current app navigation path
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/webview/webview_bridge_dispatcher_test.dart`
Expected: fail because the dispatcher does not exist yet.

- [ ] **Step 3: Write minimal implementation**

No production code yet.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/webview/webview_bridge_dispatcher_test.dart`
Expected: pass after implementation.

### Task 2: Implement bridge dispatcher and WebView page

**Files:**
- Create: `lib/app/modules/webview/webview_bridge_dispatcher.dart`
- Create: `lib/app/modules/webview/views/webview_page.dart`
- Modify: `lib/app/routes/app_routes.dart`
- Modify: `lib/app/routes/app_pages.dart`

- [ ] **Step 1: Write the failing test**

```dart
testWidgets('getPublicParams sends callback payload back to H5', (tester) async {
  // expect the callback to receive current common params
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/webview/webview_bridge_dispatcher_test.dart`
Expected: fail until dispatcher/page are added.

- [ ] **Step 3: Write minimal implementation**

Add the WebView page, bridge handler registration, action dispatch, and callback plumbing.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/webview/webview_bridge_dispatcher_test.dart`
Expected: pass.

### Task 3: Extend native bridge only if review action needs it

**Files:**
- Modify: `lib/app/core/native/native_bridge.dart`
- Modify: `test/trust_decision_liveness_test.dart` or a focused native bridge test

- [ ] **Step 1: Write the failing test**

```dart
test('requestAppReview returns success on supported platforms', () async {
  // verify the bridge call is wired
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/trust_decision_liveness_test.dart`
Expected: fail until the review entry point exists.

- [ ] **Step 3: Write minimal implementation**

Add only the review method needed for `toGrade`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/trust_decision_liveness_test.dart`
Expected: pass.
