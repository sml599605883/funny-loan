# Address Selector Design

## Scope

Update only the personal-info address selector in `CertificationPersonalInfoPage`.
Do not change other enum selectors or non-address fields.

## UI

- Keep the address field in the form as a dedicated selectable field, but refresh its visual style to better match the Lanhu `地址选择` design direction.
- Replace the current three-column always-visible address picker sheet with a modal sheet that has:
  - a dimmed full-screen backdrop
  - a white rounded content card
  - a segmented header with `Region`, `Province`, and `Municipality`
  - a single visible option list for the currently active segment
  - a selected-row check icon
  - bottom `Cancel` and `Done` buttons

## Interaction

- Tapping the address field still fetches address options from `fetchAddressOptions()`.
- The sheet no longer submits immediately when an item is tapped.
- Selecting a row updates in-sheet state only.
- `Cancel` closes the sheet without changing the field value.
- `Done` commits the current selection into the field.
- If the selected province has no cities, `Done` returns `Province-City`.
- If the selected city has districts, `Done` returns `Province-City-District`.

## Data Constraints

- Preserve existing `_PersonalAddressOption` and `_PersonalAddressNode` parsing.
- Preserve the saved submit format currently used by `field.selectAddress(...)`.
- Preserve existing API payload keys and `currentSubmitValue` behavior outside of the address sheet flow.

## Testing

- Add widget coverage for:
  - opening the address sheet
  - changing staged selection without immediate submit
  - `Cancel` keeping the old address value
  - `Done` committing the staged final address value
