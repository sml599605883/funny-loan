# Certification Upload Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let `CertificationUploadPage` pick a camera/gallery image from the Lanhu popup and upload it through `ApiService.uploadIdentityOrFace`.

**Architecture:** Keep UI protocol-free. Add a small injectable image picker abstraction for tests and a page-owned upload flow that calls the existing API service. Use `image_picker` only inside the production picker implementation.

**Tech Stack:** Flutter, GetX, `permission_handler`, `image_picker`, existing `ApiService` multipart upload.

---

### Task 1: Add Upload-Flow Test Coverage

**Files:**
- Modify: `test/certification_step_page_test.dart`

- [ ] **Step 1: Write the failing widget test**

Add a fake picker and extend `_FakeApiService` with `uploadIdentityOrFace` capture. Add a test that opens `CertificationUploadPage`, taps `Submit`, taps `Photo Album`, and expects `_FakeApiService.uploadedFilePath == '/tmp/id-front.png'`.

- [ ] **Step 2: Run the test to verify RED**

Run: `flutter test test/certification_step_page_test.dart`

Expected: FAIL because `CertificationUploadPage` has no injectable picker and source rows only log.

### Task 2: Add Image Picking Dependency And Abstraction

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/app/modules/certification_upload/views/certification_upload_page.dart`

- [ ] **Step 1: Add `image_picker` dependency**

Run: `flutter pub add image_picker`

- [ ] **Step 2: Define picker abstraction**

Create an abstract class in `certification_upload_page.dart`:

```dart
abstract class CertificationUploadImagePicker {
  Future<String?> pickFromCamera();
  Future<String?> pickFromGallery();
}
```

Create the production implementation using `ImagePicker().pickImage(...)`.

### Task 3: Implement Page Upload Flow

**Files:**
- Modify: `lib/app/modules/certification_upload/views/certification_upload_page.dart`

- [ ] **Step 1: Convert page to stateful flow owner**

Convert `CertificationUploadPage` to accept optional `imagePicker` and `apiService` dependencies and track `_isUploading`.

- [ ] **Step 2: Wire popup source rows**

Pass callbacks into `_UploadSourceSheet`: `onPhotograph`, `onPhotoAlbum`, and `onDone`. Source row taps should pick and upload immediately.

- [ ] **Step 3: Upload selected file**

Implement `_pickAndUpload`:

```dart
final filePath = await picker.pickFromGallery();
if (filePath == null || filePath.isEmpty) return;
await apiService.uploadIdentityOrFace(body: _uploadBody(), filePath: filePath);
```

Use only route payload values already available in `Get.arguments`; do not invent protocol fields.

### Task 4: Verification

**Files:**
- Test: `test/certification_step_page_test.dart`

- [ ] **Step 1: Run formatter**

Run: `dart format lib/app/modules/certification_upload/views/certification_upload_page.dart test/certification_step_page_test.dart`

- [ ] **Step 2: Run analyzer**

Run: `flutter analyze lib/app/modules/certification_upload/views/certification_upload_page.dart test/certification_step_page_test.dart`

Expected: no issues.

- [ ] **Step 3: Run widget tests**

Run: `flutter test test/certification_step_page_test.dart`

Expected: all tests pass.
