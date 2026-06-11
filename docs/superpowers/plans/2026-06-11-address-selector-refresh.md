# Address Selector Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refresh the certification personal-info address selector UI and interaction to match the Lanhu address sheet while preserving payload format and surrounding form behavior.

**Architecture:** Keep the existing personal-info page and address tree parsing intact. Replace only the address field presentation details and the address modal sheet state flow so selection is staged locally and committed only on `Done`.

**Tech Stack:** Flutter, widget tests, GetX navigation, existing `ScreenAdapter` and `AppColors`

---

### Task 1: Lock behavior with widget tests

**Files:**
- Modify: `test/certification_step_page_test.dart`
- Test: `test/certification_step_page_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
testWidgets('address sheet does not commit selection until done is tapped', (
  WidgetTester tester,
) async {
  // Open the personal info page with an initial address value.
  // Tap a different province/city/district in the address sheet.
  // Assert the form still shows the old value before tapping Done.
  // Tap Done and assert the new value appears.
});

testWidgets('address sheet cancel keeps the previous address value', (
  WidgetTester tester,
) async {
  // Open the sheet, change staged selection, tap Cancel,
  // and assert the field still shows the original value.
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/certification_step_page_test.dart --plain-name "address sheet does not commit selection until done is tapped"`
Expected: FAIL because the current sheet commits on row tap.

- [ ] **Step 3: Write minimal implementation**

```dart
// Update the address sheet to track staged indexes and
// only return a selection from the Done button.
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/certification_step_page_test.dart --plain-name "address sheet does not commit selection until done is tapped"`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add test/certification_step_page_test.dart lib/app/modules/certification_step/views/certification_personal_info_page.dart docs/superpowers/specs/2026-06-11-address-selector-design.md docs/superpowers/plans/2026-06-11-address-selector-refresh.md
git commit -m "feat: refresh personal info address selector"
```

### Task 2: Refresh the address selector sheet UI

**Files:**
- Modify: `lib/app/modules/certification_step/views/certification_personal_info_page.dart`
- Test: `test/certification_step_page_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
testWidgets('address sheet shows done and cancel actions', (
  WidgetTester tester,
) async {
  // Open the address selector and assert the two actions exist.
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/certification_step_page_test.dart --plain-name "address sheet shows done and cancel actions"`
Expected: FAIL if the new action area or updated sheet structure is missing.

- [ ] **Step 3: Write minimal implementation**

```dart
// Add segmented tabs, one visible list, selected-row check icon,
// and bottom Cancel/Done actions to _PersonalAddressSheet.
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/certification_step_page_test.dart --plain-name "address sheet shows done and cancel actions"`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add test/certification_step_page_test.dart lib/app/modules/certification_step/views/certification_personal_info_page.dart
git commit -m "feat: restyle address selector sheet"
```

### Task 3: Verify the focused regression surface

**Files:**
- Modify: `lib/app/modules/certification_step/views/certification_personal_info_page.dart`
- Test: `test/certification_step_page_test.dart`

- [ ] **Step 1: Run the focused personal-info tests**

Run: `flutter test test/certification_step_page_test.dart`
Expected: PASS

- [ ] **Step 2: Review for accidental behavior changes**

```text
Check that only address selector behavior changed:
- enum selector still commits through its existing sheet
- submit payload still uses the same address string format
- cancel path does not mutate form state
```

- [ ] **Step 3: Commit**

```bash
git add test/certification_step_page_test.dart lib/app/modules/certification_step/views/certification_personal_info_page.dart
git commit -m "test: cover address selector confirm flow"
```
