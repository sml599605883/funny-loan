# Certification Upload Flow Design

## Scope

Complete the upload flow behind `CertificationUploadPage` after the current Lanhu-based source-selection popup. The flow starts when the user taps `Submit`, chooses `Photograph` or `Photo Album`, selects an image, and the app uploads the selected file through the existing certification upload API.

## Current Context

- `CertificationUploadPage` already renders the upload UI and opens a Lanhu-matched bottom sheet.
- `ApiService.uploadIdentityOrFace` already owns the upload endpoint `/consultancy/miniaturized`.
- `NetworkClient.upload` already builds multipart requests and attaches files under the existing `UploadFilePart` abstraction.
- `permission_handler` is already present.
- The project does not currently include an image picking dependency.

## Chosen Approach

Use Flutter image picking for camera and gallery source selection, then call `ApiService.uploadIdentityOrFace(filePath: selectedPath, body: payload)` from a small page controller owned by `CertificationUploadPage`. Keep all protocol details in `ApiService` and avoid direct Dio usage in the UI.

This keeps the implementation small and follows the `project_docs/network/network_skill.md` rule that upload placement and protocol handling stay centralized in the network layer.

## UI Flow

1. User taps `Submit`.
2. Bottom source-selection popup opens.
3. User taps `Photograph`.
4. App requests camera permission if required.
5. App opens the camera picker.
6. If a file is selected, popup closes and upload starts.
7. User taps `Photo Album`.
8. App opens the gallery picker.
9. If a file is selected, popup closes and upload starts.
10. `Cancel` and close dismiss the popup without side effects.

## Upload Behavior

- Upload uses `Get.find<ApiService>().uploadIdentityOrFace(...)`.
- The selected file path is passed as `filePath`.
- The multipart file field remains `attach`, as defined by `ApiService`.
- Request body will be built only from available route payload and selected ID context.
- Do not invent undocumented protocol fields.
- Upload success initially updates local UI/log state only.
- Navigation after upload should only be added if the API response contains a clear next-step route that existing navigation helpers can handle.

## State And Errors

- Show an uploading state so repeated taps cannot start parallel uploads.
- If permission is denied, dismiss the popup and show a lightweight error message.
- If the picker is cancelled, do nothing.
- If upload fails, show the error and restore the normal button state.
- Network failures must not crash the page.

## Dependencies

- Add an image picking dependency if implementation confirms no existing project picker is available.
- Keep permission handling aligned with the existing `AppPermissionService` where possible.

## Testing

- Keep the existing popup display test.
- Add a test that taps `Submit` and verifies the source actions are present.
- Add an injectable image-picking dependency so widget tests can fake a selected image path without real platform channels.
- Add a fake `ApiService` assertion that selected file paths are passed to `uploadIdentityOrFace`.
- Keep existing certification step navigation tests passing.

## Risks

- The exact request body fields for `/consultancy/miniaturized` are not fully documented in the current UI code. The implementation must use only confirmed payload fields or leave the body empty if no safe fields exist.
- Native camera/gallery permission configuration may require platform manifest updates after dependency selection.
