# Debug TODO

## Deferred: `PiwigoAPI.checkPhoto` tri-state handling

Goal: avoid duplicate uploads when `checkPhoto` fails for transient/API reasons.

### Proposed approach

- Classify `checkPhoto` outcomes as:
  - `exists`
  - `not_found` (authoritative missing)
  - `check_failed` (network/session/timeout/unknown response)
- In `PublishTaskImageProcessing.processRenderedPhotos`:
  - Upload only on confirmed `not_found`
  - Retry (or relogin + retry) on `check_failed`
  - If still uncertain after retry, fail/defer safely instead of assuming missing
- Add clear logging for outcome class at each decision point.

### Safety / rollout

- Do not change `PiwigoAPI.checkPhoto` behavior globally until all call sites are reviewed.
- Start with local handling at the `processRenderedPhotos` call site.
- Then review all other `checkPhoto` call sites for compatibility before shared API changes.

## Deferred: render optimization

- Investigate skipping the first default render when per-album custom settings are enabled.
- Revisit `rendition:skipRender()` reliability and callback behavior.
- Consider applying the same skip strategy to association/no-upload scenarios.

## Current status

- Custom re-render resize path is working (confirmed upload at 1024x683).
- Property table wrapper (`"< contents >"`) is now being unwrapped for custom render settings.
