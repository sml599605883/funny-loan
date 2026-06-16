# Funny Loan Unified WebView Navigation Design

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Route all in-app web navigation through the new `webview_page`, while keeping only `WebViewBridgeAction.openExternalBrowser` as a true external-browser escape hatch.

**Architecture:** Introduce one app-level helper, `NavigationHelper.toWebView(url)`, as the single entry point for app-internal web pages. Update navigation/dispatch code so any `http/https` or resolved `/#/` H5 target opens the app’s WebView route instead of using `url_launcher`, while bridge-only external-browser requests continue to use `launchUrl(...externalApplication)`.

**Tech Stack:** Flutter, GetX, `webview_flutter`, existing Funny Loan routing/bridge helpers, focused Flutter tests.

---

## Requirements

- `NavigationHelper.toWebView(url)` becomes the only in-app web open helper.
- `toWebView` only accepts `url`; no `title` parameter.
- `FunnyLoanWebViewPage` starts with app bar title `Loading...`.
- After page load, the WebView page reads the document title and uses it as the app bar title.
- `ApiNavigationHelper` must stop using `launchUrl` for regular web targets.
- `http/https` targets open in `webview_page`.
- Relative `/#/...` targets resolve against `webBaseUrl`, then open in `webview_page`.
- Only `WebViewBridgeAction.openExternalBrowser` should continue opening the external browser.
- Existing native/app-page route handling must remain unchanged.

## Scope

- In scope:
  - Unified app-internal web navigation helper.
  - `ApiNavigationHelper` web target dispatch changes.
  - WebView page title behavior update.
  - Focused tests for unified routing and title defaults.
- Out of scope:
  - Changing external-browser bridge behavior.
  - Reworking route stack cleanup beyond this single unification task.

## Risks

- Existing tests that assume external browser launch on regular web targets will need to be rewritten.
- Any hidden direct `launchUrl` web usage outside current route helpers must be found and normalized.
