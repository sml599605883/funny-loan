# Funny Loan Unified WebView Navigation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make all app-internal web navigation open the Funny Loan WebView page through one shared helper.

**Architecture:** Add one routing helper for WebView entry and route all standard web targets through it. Keep external-browser behavior isolated to the bridge action that explicitly requests it.

**Tech Stack:** Flutter, GetX, `webview_flutter`, current Funny Loan routing/tests.

---

### Task 1: Add failing tests for unified web navigation

**Files:**
- Modify: `test/routes/navigation_helper_test.dart`
- Modify: `test/routes/api_navigation_helper_test.dart`
- Modify: `test/webview/webview_bridge_dispatcher_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
testWidgets('web targets open AppRoutes.webview instead of external browser', (tester) async {
  // route to a normal web target and expect the webview page
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/routes/navigation_helper_test.dart test/routes/api_navigation_helper_test.dart test/webview/webview_bridge_dispatcher_test.dart`
Expected: FAIL because regular web targets still rely on older behavior or missing helper coverage.

- [ ] **Step 3: Write minimal implementation**

No production code yet.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/routes/navigation_helper_test.dart test/routes/api_navigation_helper_test.dart test/webview/webview_bridge_dispatcher_test.dart`
Expected: PASS after implementation.

### Task 2: Implement `NavigationHelper.toWebView(url)` and route all internal web targets through it

**Files:**
- Modify: `lib/app/routes/navigation_helper.dart`
- Modify: `lib/app/routes/api_navigation_helper.dart`
- Modify: `lib/app/routes/app_pages.dart`
- Modify: `lib/app/modules/webview/views/webview_page.dart`

- [ ] **Step 1: Write the failing test**

```dart
testWidgets('toWebView opens the webview route with Loading title first', (tester) async {
  // navigate via helper and expect the page to mount
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/routes/navigation_helper_test.dart`
Expected: FAIL until the helper and page behavior are wired.

- [ ] **Step 3: Write minimal implementation**

Add `toWebView(url)`, change normal web dispatch to use it, keep only explicit external-browser flow outside it, and make the page title start from `Loading...` then update from the loaded document title.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/routes/navigation_helper_test.dart test/routes/api_navigation_helper_test.dart test/webview/webview_bridge_dispatcher_test.dart`
Expected: PASS.
