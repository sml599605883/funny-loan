# Certification Work Info Page Design

## Goal

Add a standalone certification work-info page that follows the existing personal-info page structure, uses the Lanhu design `认证-工作信息` as the visual reference, and is entered through product-detail next-step routing after the personal-info step.

## Scope

In scope:

- Add a new standalone work-info page under the certification-step module
- Route normalized product-detail next-step `job` to the new page
- Reuse the current fetch/save user-info protocol and dynamic field rendering
- Update the page to use `assets/certification/certification_personal_progress_step2.png`
- Add focused widget coverage for the new page and routing handoff

Out of scope:

- Refactoring the existing personal-info page into a generic shared form shell
- Changing product-detail parsing contract or next-step payload keys
- Adding new backend request methods or changing the `saveUserInfo()` contract
- Implementing later steps such as emergency contact in this task

## Current Context

The repo already has a standalone `CertificationPersonalInfoPage` that:

- reads page arguments from the product-detail payload
- fetches dynamic field definitions from `ApiService.fetchUserInfo()`
- renders text, enum, and address fields from the returned schema
- submits values through `ApiService.saveUserInfo()`
- calls the product-detail flow runner after submit success so the backend decides the next route

The routing stack also already normalizes product-detail auth codes through `NavigationTargetMapper`, and dispatches native app targets through `NavigationHelper.toAppPage()`.

## Recommended Approach

Create a separate `CertificationWorkInfoPage` that keeps the same behavioral contract as `CertificationPersonalInfoPage`, while staying isolated as its own page, route helper, and tests.

This is the safest option because:

- it matches the requested UX boundary of “personal info first, then a new independent work-info page”
- it keeps the existing personal-info implementation stable
- it keeps product-detail next-step orchestration in one place instead of hardcoding local page-to-page jumps
- it avoids premature abstraction in a part of the repo that was just stabilized

## Rejected Alternatives

### 1. Generic shared form-shell refactor now

This would reduce duplication, but it expands scope and risk. The certification pages are still actively changing, and a base-form abstraction would create a larger diff than needed for this task.

### 2. Keep using the generic `certificationStep` route for `job`

This would avoid adding a dedicated page route, but the route meaning becomes blurry and later certification steps become harder to test and maintain independently.

## Design

### Page structure

Add `CertificationWorkInfoPage` beside the existing certification pages in:

- `lib/app/modules/certification_step/views/`

The page should keep the same high-level layout split already validated on the personal-info page:

- fixed header
- fixed hint banner
- fixed bottom submit button
- scrollable white rounded content area in the middle

Visual adaptations for this page:

- title resolves from the same next-step payload and should display `Work Information` for the Lanhu-driven path
- top progress asset uses `assets/certification/certification_personal_progress_step2.png`
- field order and labels come from `fetchUserInfo()` response, not hardcoded local field definitions

### Routing

The page should be wired as a first-class standalone route, parallel to the personal-info page.

Expected routing behavior:

- product detail returns next-step target/code
- `NavigationTargetMapper` normalizes the raw backend value
- normalized `job` dispatches to the new work-info route
- face-page success still only refreshes product detail
- the backend remains the source of truth for whether the next native step is `personal`, `job`, or something later

This preserves the repo’s current pattern where page-to-page movement is decided centrally from product-detail state.

### Data flow

The work-info page should reuse the same protocol shape already used by personal info:

1. Read `productId` and `nextStepTitle` from route payload
2. Call `ApiService.fetchUserInfo({'cohabiter': productId})`
3. Parse `rekeys.tingling` or `tingling` into field models
4. Render each field according to its returned type
5. Build submit body as:
   - `cohabiter: productId`
   - one entry per returned field using `field.saveKey -> field.currentSubmitValue`
6. Call `ApiService.saveUserInfo(body)`
7. On success, call the product-detail flow runner with the same `productId`

No new request methods or alternate payload names should be introduced.

### Field rendering

Do not create a work-only field model.

Reuse:

- `PersonalInfoFieldData`
- `PersonalInfoFieldOption`
- `EnumSelectionSheet`
- `AddressSelectionSheet`

Rendering rules stay unchanged:

- text fields render as `TextField`
- enum/select fields open `EnumSelectionSheet`
- city/address fields open `AddressSelectionSheet`

This keeps the implementation aligned with the existing backend-driven form schema.

### Error handling

Match current certification behavior:

- loading state while fetching
- retry state on fetch failure using `NetworkErrorMapper.map(error)`
- toast/error feedback for selection and submit failures
- no route transition when `productId` is missing or submit fails

No speculative validation layer should be added unless the returned schema requires it.

## Testing

Add focused coverage in `test/certification_step_page_test.dart`.

Required regression checks:

- face flow refreshes product detail and a `job` next-step dispatch lands on the work-info page
- work-info page renders independently with the expected title and step-2 progress asset
- submit body contains `cohabiter` plus the exact returned work-field keys
- at least one selectable field path still works on the new page
- at least one text or address field path still works on the new page

The test strategy should stay surgical: extend the current certification widget suite rather than creating a new broad test harness.

## Files Expected To Change

- `lib/app/modules/certification_step/views/certification_work_info_page.dart`
- `lib/app/routes/app_routes.dart`
- `lib/app/routes/app_pages.dart`
- `lib/app/routes/navigation_helper.dart`
- `lib/app/routes/navigation_target_mapper.dart`
- `test/certification_step_page_test.dart`

Potentially:

- a small shared argument model/helper only if needed to avoid copy-paste drift, but only if the reuse is direct and minimal

## Success Criteria

- A standalone work-info page exists and visually follows the personal-info page structure plus the step-2 progress asset
- Backend-driven next-step `job` opens the work-info page through centralized routing
- The page fetches and submits through the existing user-info APIs without contract changes
- Focused widget tests cover rendering, submit payload, and route handoff

## Risks

- The backend may return work-info fields through the same `fetchUserInfo()` endpoint but with type combinations not covered by the current page assumptions
- Routing may already rely on `job` falling through `certificationStep`; changing dispatch must not break any existing generic certification entry

These are contained by keeping the change isolated and covering the new route with targeted widget tests.
