# Funny Loan WebView Bridge Design

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Funny Loan WebView page with H5 bridge handling that maps web actions to the current app's navigation, native, and network capabilities.

**Architecture:** A dedicated WebView page owns lifecycle, loading state, and JS bridge registration. A separate bridge dispatcher translates H5 actions into existing Funny Loan behaviors through `NavigationHelper`, `ApiNavigationHelper`, `NativeBridge`, and network common-parameter construction. The page should only expose a minimal surface: URL/title input, back handling, and JS message forwarding.

**Tech Stack:** Flutter, GetX, `url_launcher`, existing Funny Loan routing/network/native modules, `flutter_inappwebview` or the current WebView package already used in the repo.

---

## Requirements

- `ph_funny_loan_ios` is the JS bridge name.
- Supported actions:
  - `funny_loan_ehjDgwoW4zPWQ3a`
  - `funny_loan_wlxa8eauNT2W09N`
  - `funny_loan_d2ayej1pMyRIQsi`
  - `funny_loan_L4vkZvEjZiRkEG8`
  - `funny_loan_VqYC7ZnNKMSymiK`
  - `funny_loan_i2QVBh8rv3SeVky`
  - `funny_loan_SvmXa7766ceTANO`
  - `funny_loan_XpRsQGeB5cl54PY`
  - `funny_loan_IZqKAOAYtuyHub9`
- `openUrl` must use current-project URL handling first, not `cash_pinoy` page logic.
- `changeAccount` and `retryOrderDialog` must resolve to current-project routes/API flows.
- `getPublicParams` must return current-project common parameters to H5 through the callback.
- H5 bridge handling must be disabled when the page is not active or the app is backgrounded.
- `toGrade` must go through the existing Funny Loan native bridge surface, extending it only if needed.
- The page must support back navigation and H5-triggered close/home behavior.

## Scope

- In scope:
  - New WebView page.
  - JS bridge dispatcher.
  - Any minimal `NativeBridge` additions required for review flow.
  - Route registration.
  - Focused tests for action dispatch and callback behavior.
- Out of scope:
  - Rewriting existing home/certification/order flows.
  - Copying `cash_pinoy` pages or route names.
  - Adding new backend APIs.

## Risks

- The repo may not yet have a dedicated WebView widget, so the implementation may need a new dependency or reuse an existing one.
- `changeAccount` and `retryOrderDialog` are product-specific; the exact current-project target may require one iteration of route tracing.
- `toGrade` may require a minimal iOS/Android native channel update if no existing review API is present.
