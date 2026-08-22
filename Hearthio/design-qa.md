# Add-item two-step flow design QA

## Visual truth

- Selection page: `/Users/starburst/.codex/generated_images/01a023c9-2e04-7273-ab1b-7723c5c2121b/exec-54667f6c-8ed3-4e35-a15e-8eea1fd67ac9.png`
- Supplement page: `/Users/starburst/.codex/generated_images/01a023c9-2e04-7273-ab1b-7723c5c2121b/exec-863abce3-e355-4aa3-b98c-87830f17b73c.png`
- Return-button control: `/Users/starburst/.codex/generated_images/01a023c9-2e04-7273-ab1b-7723c5c2121b/exec-0fa71858-083e-4633-a8da-cd7963c7aa7a.png`

## Runtime capture

- Environment: iPhone 17 Pro simulator, iOS 26.5, portrait.
- Selection state: search empty, common items visible, `家用电器` expanded.
  - Implementation: `/private/tmp/hearthio-after-click.png`
- Supplement state: `空调` selected, optional groups collapsed, keyboard dismissed.
  - Implementation: `/private/tmp/hearthio-back-button-supplement-fixed-final-c.png`
- The original flow sources are 853 x 1858; the return-control source is 853 x 1844. Simulator captures are 1206 x 2622 and include the iOS status/safe-area chrome. Full-view flow comparisons scale captures to the source density. The focused return-control comparison excludes only the implementation's 170-pixel iOS status/safe-area region before normalization.

## Comparison evidence

- Full-view selection comparison, source left and implementation right:
  `/private/tmp/hearthio-selection-comparison.png`
- Full-view supplement comparison, source left and implementation right:
  `/private/tmp/hearthio-supplement-comparison.png`
- Focused category-directory comparison:
  `/private/tmp/hearthio-selection-focus-comparison.png`
- Focused selected-item and optional-fields comparison:
  `/private/tmp/hearthio-supplement-focus-comparison.png`
- Focused return-button comparison, app-owned content aligned after excluding the implementation's 170-pixel iOS status/safe-area region:
  `/private/tmp/hearthio-back-button-focus-comparison-content.png`

## Findings and iteration history

1. The first runtime pass matched the intended hierarchy: search/common/category directory on step 1, then selected-item summary/optional details/deferred advanced information on step 2.
2. Independent flow review found a P1 navigation issue: the supplement page's `PopScope` could block the programmatic pop after save. The flow now temporarily enables route exit after persistence and pops on the next frame. A route-level Widget test covers the return behavior.
3. Final full-view and focused comparisons found no remaining P0, P1, or P2 issue. Differences limited to platform-safe-area spacing and available Material symbol shapes are P3 polish differences and do not change the selected structure or interaction.
4. A later P2 visual review found that the AppBar constraints stretched the return-button background into a vertical capsule. The button now uses a fixed 40 x 40 logical-pixel box and `CircleBorder`; the post-fix iPhone 17 Pro capture and focused comparison confirm a circular control on both selection and supplement pages. The remaining few-pixel size difference from the generated reference is P3 density polish.

## Final result

passed

---

# Shared app alert design QA

## Source and implementation truth

- Selected visual direction: `/Users/starburst/.codex/generated_images/01a02799-4cf7-7e03-ad2f-565c0ee9b081/exec-a567d264-618d-42b7-aa6e-fec3739f968d.png`.
- Selected source dimensions: 853 x 1844 pixels, generated for a 390 x 844 logical-pixel mobile target.
- Final simulator capture: `/Users/starburst/Donesome/Hearthio/qa-artifacts/app-alert-simulator-final.png`.
- Runtime viewport: iPhone 17 Pro simulator, iOS 26.5, 402 x 874 logical pixels at 3x density; capture is 1206 x 2622 pixels.
- State: destructive two-action confirmation with title `删除这个计划？`, the selected mock's `清洗滤网` message, green cancel action, and red confirm action. A task-local preview entrypoint opened the production `showAppAlert` component over the real item editor so the exact alert could be inspected without mutating simulator data.

## Density normalization and comparison evidence

- The selected source was proportionally enlarged to fill 1206 x 2622 and center-cropped horizontally to that exact size; the source was not stretched.
- Normalized source: `/Users/starburst/Donesome/Hearthio/qa-artifacts/app-alert-reference-normalized.png`.
- Full-view source-left / implementation-right comparison: `/Users/starburst/Donesome/Hearthio/qa-artifacts/app-alert-comparison-final.png`.
- Focused alert source-left / implementation-right comparison: `/Users/starburst/Donesome/Hearthio/qa-artifacts/app-alert-focus-comparison-final.png`.
- The source omits platform chrome while the simulator capture preserves the real iOS status bar and safe area. The focused comparison isolates app-owned Alert pixels.

## Required fidelity surfaces

- Fonts and typography: the implementation uses the native iOS Chinese system fallback with a 20-point bold title, 16-point body at 1.5 line height, and 17-point action labels. Title hierarchy and the two-line message wrap match the selected source. Native glyph width and weight differ slightly from ImageGen rendering and remain P3.
- Spacing and layout rhythm: the final surface is 318 logical pixels wide with 24-point continuous corners, 24-point horizontal content inset, 28-point top inset, 18-point title-to-message gap, and 60-point minimum action rows. The title, message, hairline action divider, and equal-width action row preserve the selected top-to-bottom structure.
- Colors and visual tokens: paper `#FFFEFA`, ink `#263630`, green `#137B67`, destructive red `#B42318`, divider `#E2E9E2`, and the neutral translucent scrim reproduce the selected semantics while remaining consistent with Hearthio's existing palette.
- Image quality and assets: the Alert contains no raster image, decorative illustration, custom SVG, emoji, or placeholder. The comparison uses code-rendered native typography and surfaces only.
- Copy and content: title, message, cancel label, and destructive label match the selected source exactly. Longer guidance automatically becomes left-aligned and scrollable while short confirmations retain the centered source treatment.
- Accessibility and responsiveness: the Alert exposes a scoped route semantic label, actions remain at least 60 points tall, a single action spans the full footer, two actions divide equally, and three or more actions stack. A compact 320 x 480 Widget viewport verified long copy remains scrollable without hiding actions or overflowing.

## Interaction and regression evidence

- Source scan confirms all six former production `AlertDialog` call sites now route through `showAppAlert`; only the shared component owns `showDialog`.
- Component and permission Widget tests pass 8 tests, covering title-message-actions order, equal footer sizing, single- and multi-action full-width rows, semantic colors, return values, long-content scrolling, and the preserved system-settings action key.
- The main Widget regression suite passes 43 tests, including notification primer, backup restore guidance, plan deletion/archival, item deletion, and maintenance-record deletion flows.
- `flutter analyze` reports no issues, and the full local Flutter suite passes 123 tests. `flutter run` built, installed, and launched the current main app on the booted iPhone 17 Pro simulator before the dedicated visual state was captured.
- No physical-device, archive, TestFlight, or App Store evidence is claimed.

## Comparison history

### Pass 1 findings

- [P2] The first implementation used a 326-point maximum width while the normalized selected source measured about 318 points, making the Alert feel slightly broader.
- [P2] The first action footer used a 56-point minimum height while the selected source measured about 60 points, reducing the intended iOS action rhythm.

### Fixes and final evidence

- Reduced the shared Alert maximum width to 318 points and increased action rows to a 60-point minimum while preserving the long-content height constraint.
- The final focused comparison confirms matching two-line copy, corner treatment, divider placement, equal action widths, semantic action colors, and overall proportions.
- No actionable P0, P1, or P2 issue remains.

## Follow-up polish

- [P3] Native iOS Chinese glyph metrics and antialiasing differ slightly from the generated source.
- [P3] The real iOS status bar shifts the centered Alert slightly lower than the chrome-free source; the component remains centered within the safe presentation area.

## Final result

passed

---

# Maintenance execution timeline redesign QA

## Visual truth and runtime states

- Selected direction: `/Users/starburst/.codex/generated_images/01a0274c-92e5-7ea0-bca4-7cb3bd76c6e7/exec-928f8012-c991-4662-9466-58f10c6fcfd0.png`
- Source dimensions: 853 x 1844 pixels, generated for a compact portrait mobile target.
- Initial implementation capture: `/Users/starburst/Donesome/Hearthio/qa-artifacts/maintenance-home-before-navigation.png`
- Completed implementation capture: `/Users/starburst/Donesome/Hearthio/qa-artifacts/maintenance-execution-implementation-final.png`
- Runtime viewport: iPhone 17 Pro simulator, iOS 26.5, 402 x 874 logical pixels at 3x density; capture is 1206 x 2622 pixels.
- The initial capture proves the requested disabled CTA state. The completed capture proves the green enabled state after all four steps are checked.

## Comparison evidence

- Same-state initial full comparison, source left and implementation right: `/Users/starburst/Donesome/Hearthio/qa-artifacts/maintenance-execution-comparison-v1.png`
- Same-state initial focused comparison: `/Users/starburst/Donesome/Hearthio/qa-artifacts/maintenance-execution-focus-comparison-v1.png`
- Completed-state full comparison retained as state evidence: `/Users/starburst/Donesome/Hearthio/qa-artifacts/maintenance-execution-comparison-final.png`
- Completed-state focused comparison: `/Users/starburst/Donesome/Hearthio/qa-artifacts/maintenance-execution-focus-comparison-final.png`
- The implementation capture was proportionally normalized to 853 x 1854 and center-cropped to 853 x 1844 before comparison. The real iOS status bar and safe-area chrome remain expected platform-owned differences.

## Required fidelity surfaces

- Information hierarchy: the compact task summary, neutral `执行步骤` heading, numbered timeline, step descriptions, five recording shortcuts, and fixed completion action preserve the selected direction.
- User-intent overrides: the source's dynamic `还剩 4 步` was intentionally replaced by `执行步骤`, and its initially green CTA was intentionally replaced by a disabled CTA until every step is complete.
- Step state: the current step uses a green ring and directional marker; a tap converts it to a green check and automatically advances the current highlight. Completed titles receive a line-through treatment while descriptions remain readable.
- Completion records: date, cost, material, note, and photo use five equal horizontal shortcuts. Date uses the shared picker; text records and before/after photos use compact bottom sheets so the primary timeline remains uninterrupted.
- Fonts, color, and assets: the native iOS Chinese font, existing Hearthio forest/sage/paper tokens, project purifier PNG, and Material icon family are used. No missing raster asset, placeholder, emoji, or code-drawn substitute is present.
- Accessibility: timeline rows expose numbered title, description, current/completed state, and toggled semantics; primary controls retain practical touch targets and the fixed action area includes the system bottom inset.

## Interaction and regression evidence

- The iPhone-viewport Widget test verifies all four descriptions and five shortcuts, the initially disabled CTA, shared date-picker opening, sequential current-step semantics, check-count progression, and final enabled CTA.
- The execution flow test verifies cost, material, note, before/after photo recording, completion, and persisted record values.
- Failure and rapid-double-submit tests verify retry visibility and submission locking.
- Legacy built-in plans are enriched with template descriptions without changing step identifiers; serialization remains backward compatible when descriptions are absent.
- `flutter analyze` reports no issues. The full local suite passes 116 tests.
- `flutter run` built, installed, and launched the current code on the booted iPhone 17 Pro simulator. No physical-device, archive, TestFlight, or App Store evidence is claimed.

## Final review

- No actionable P0, P1, or P2 issue remains in the same-state source/implementation comparison.
- [P3] Native Chinese glyph metrics and Material icon contours differ slightly from ImageGen rendering.
- [P3] The real status bar shifts app-owned content lower than the chrome-free source.
- [P3] The persisted simulator sample shows its real next-date status instead of the source's illustrative `今天到期`; this is a data-state difference rather than design drift.

## Final result

passed

---

# Shared date picker design QA

## Visual truth and runtime state

- Selected source: `/Users/starburst/.codex/generated_images/01a0272f-79a3-7b40-94b9-c275df10d08d/exec-3bf405bc-143b-4dca-83d2-1995e83910fa.png`
- Source dimensions: 853 x 1844 pixels, generated for a 390 x 844 logical-pixel mobile target.
- Final implementation capture: `/Users/starburst/Donesome/Hearthio/qa-artifacts/date-picker-implementation-final.png`
- Runtime viewport: iPhone 17 Pro simulator, iOS 26.5, 402 x 874 logical pixels at 3x density; capture is 1206 x 2622 pixels.
- State: 2026-08-22 is today, 2026-08-23 is selected, and the caller's first selectable date is 2026-08-23. Today and earlier dates therefore use the real disabled treatment while the selected date stays active.

## Density normalization and comparison evidence

- The 853 x 1844 source was proportionally enlarged, center-cropped, and normalized to the simulator capture's 1206 x 2622 pixels. Both sides therefore use identical comparison dimensions without horizontally stretching the calendar.
- Full-view source-left / implementation-right comparison: `/Users/starburst/Donesome/Hearthio/qa-artifacts/date-picker-comparison-final.png`
- Focused sheet source-left / implementation-right comparison: `/Users/starburst/Donesome/Hearthio/qa-artifacts/date-picker-focus-comparison-final.png`
- First-pass full comparison retained for iteration history: `/Users/starburst/Donesome/Hearthio/qa-artifacts/date-picker-comparison-v1.png`
- The source includes an illustrative home indicator while the running app follows the simulator's system-owned indicator visibility. That platform-chrome difference is outside the app-owned component.

## Required fidelity surfaces

- Fonts and typography: the implementation uses the native iOS Chinese system fallback. The title, month label, weekday captions, day numbers, and action hierarchy match the selected source; minor native glyph and weight differences are P3.
- Spacing and layout rhythm: the final sheet occupies about 63% of the viewport, keeps the 28-pixel top radius and drag handle, preserves a six-row calendar, and pins the actions above the bottom safe area. Header, grid, and footer remain stable on tested 375 x 667 portrait and 834 x 1194 tablet viewports; a 667 x 375 landscape viewport becomes vertically scrollable instead of overflowing.
- Colors and visual tokens: paper `#FFFEFA`, forest green `#31584B`, ink `#263630`, muted sage `#72817A`, disabled sage, divider, scrim, selected fill, and today outline follow the selected direction and existing Hearthio tokens.
- Image quality and asset fidelity: the picker contains no missing raster asset or generated placeholder. Month arrows use the project's existing Material icon family; calendar state markers are native UI shapes rather than substituted artwork.
- Copy and content: all shared component copy is Chinese: `选择日期`, `今天`, weekday abbreviations, `取消`, and `完成`. Month and date values come from the caller's actual state.
- Accessibility and interactions: month arrows use 48-point controls, header/actions use at least 44-point controls, and each 36-point visual date marker retains a tested 44-point-or-larger hit region. Every date exposes enabled, selected, today, and full-date semantics.

## Interaction evidence

- Manual simulator path: Home -> `稍后提醒` -> `自定义日期` opened the shared picker inside the existing nested sheet without overflow or runtime errors.
- Component tests cover staged selection before confirmation, cancel returning null, month switching, caller-provided minimum/maximum dates, disabled today state, and compact-iPhone/iPad layout.
- Source scan confirms all five former `showDatePicker` calls now route through `showAppDatePicker`; no legacy Material/Cupertino date-picker call remains under `lib/`.

## Comparison history

### Pass 1 findings

- [P2] The first implementation was about 20 logical pixels taller than the selected source, making the sheet feel heavier.
- [P2] The confirmation action consumed too much footer width and the selected/today circles were visibly larger than the source.

### Fixes

- Reduced the responsive sheet-height factor while retaining enough height for all six calendar rows and safe-area actions.
- Rebalanced the footer to a bounded confirmation width and reduced the visual date markers from 40 to 36 logical pixels.
- Preserved accessibility by separating the 36-point marker from its at-least-44-point interactive region and added a Widget-test assertion for that boundary.

### Final comparison

- The final full-view and focused comparisons show no actionable P0, P1, or P2 mismatch.
- [P3] The native Chinese glyph metrics, flat runtime button fill, and confirmation width differ by a few pixels from ImageGen rendering, without changing hierarchy or usability.

## Final result

passed

---

# Home dashboard redesign QA

## Visual truth

- Selected source: `/Users/starburst/.codex/generated_images/01a02703-33e2-77c2-a678-d4147a0e8c36/exec-efd8f567-992a-47e4-887b-919d2659435b.png`
- Source dimensions: 853 x 1844 pixels, generated for a 390 x 844 logical-pixel mobile target.
- Final implementation capture: `/private/tmp/hearthio-home-v3.png`
- Runtime viewport: iPhone 17 Pro simulator, iOS 26.5, 402 x 874 logical pixels at 3x density; capture is 1206 x 2622 pixels.
- State: 2026-08-22; one item in one room; no attention task; next task is `示例 · 厨房净水器 / 更换滤芯`, due 2027-02-17 in 179 days; annual maintenance is ¥100 and asset value is ¥0.

## Density normalization and evidence

- The implementation capture was resized to 853 x 1854 and center-cropped by 5 pixels at the top and bottom to 853 x 1844. The full-view comparison therefore uses equal pixel dimensions without horizontally stretching either artifact.
- The generated source intentionally omits iOS chrome. The implementation preserves the real iOS status bar and safe areas; those system-owned pixels are treated as an expected runtime difference rather than app-owned design drift.
- Full-view source-left / implementation-right comparison: `/private/tmp/hearthio-home-comparison-v3.png`
- Focused task-and-overview source-left / implementation-right comparison: `/private/tmp/hearthio-home-focus-comparison-v3.png`
- First-pass comparison retained for iteration history: `/private/tmp/hearthio-home-comparison-v1.png`
- First-pass focused comparison: `/private/tmp/hearthio-home-focus-comparison-v1.png`

## Required fidelity surfaces

- Fonts and typography: the app uses the native iOS system font with the Chinese system fallback. Display weights, body sizes, single-line truncation, and hierarchy match the source intent. Minor optical differences from ImageGen letterforms remain P3.
- Spacing and layout rhythm: the 20-pixel page margins, 22-pixel hero radius, timeline grouping, vertically stacked task actions, overview dividers, and bottom dock preserve the selected composition. The final overview card is fully visible above the dock at the initial scroll position.
- Colors and tokens: canvas `#F7F8F3`, paper `#FFFEFA`, forest green `#31584B`, ink `#263630`, muted sage `#72817A`, mist `#EAF1E9`, and apricot timing accent are mapped to the existing Hearthio tokens.
- Image quality and asset fidelity: the hero room scene and purifier icon are project-local transparent PNG assets generated from the selected visual direction. The final simulator capture shows clean edges, correct tinting, and no checkerboard, halo, placeholder, or code-drawn substitute.
- Copy and content: the visible date, task, timing, status, annual cost, asset value, room count, and item count come from the app state. No health score, prediction, or invented device fact was added.
- Icons and accessibility: standard controls use the existing Material icon family. Add, schedule, start, snooze, and bottom-tab targets retain semantic buttons or tested widget actions; long values scale down and task names truncate rather than overflow.

## Interaction evidence

- Header add action opens the item-selection flow: Widget test.
- `查看日程` selects the schedule tab: Widget test.
- `开始保养` opens the exact maintenance execution flow and `稍后提醒` preserves the original due state: existing Widget tests in the full suite.
- Bottom navigation remains functional: primary-page Widget flow.
- Simulator evidence is visual. `flutter run` launched the final code on the booted iPhone 17 Pro without a runtime error; interactive behavior is supported by Widget tests rather than represented as manual simulator-tap proof.

## Comparison history

### Pass 1 findings

- [P2] The generic toolbox icon did not match the selected purifier subject.
- [P2] `开始保养` and `稍后提醒` were horizontal while the source stacks them vertically.
- [P2] The household overview card sat too close to the persistent dock and its lower edge was not cleanly visible at the initial position.

### Fixes

- Added a dedicated transparent purifier line asset and selected it for purifier/filter tasks.
- Stacked the primary and secondary maintenance actions to match the source hierarchy.
- Tightened non-semantic gaps and the overview height while preserving readable tap targets and the hero/task proportions.

### Pass 2 evidence

- `/private/tmp/hearthio-home-comparison-v3.png` and `/private/tmp/hearthio-home-focus-comparison-v3.png` confirm the purifier icon, vertical actions, full overview card, and bottom-dock separation.
- No actionable P0, P1, or P2 mismatch remains.

## Follow-up polish

- [P3] The real iOS status bar moves app-owned content slightly lower than the chrome-free source.
- [P3] Native iOS Chinese glyph metrics and a few Material icon contours differ slightly from generated artwork.
- [P3] The task-to-overview gap is slightly tighter than the source so all core content remains visible above the real safe-area dock.

## Final result

passed

---

# Maintenance before-and-after photo flow adjustment QA

## Source and implementation truth

- Selected visual direction: `/Users/starburst/.codex/generated_images/01a0274c-92e5-7ea0-bca4-7cb3bd76c6e7/exec-928f8012-c991-4662-9466-58f10c6fcfd0.png`
- User-approved structural override: move optional before-maintenance capture ahead of the timeline; keep optional after-maintenance capture after the timeline and unlock it only when all steps are complete.
- Initial implementation capture: `/Users/starburst/Donesome/Hearthio/qa-artifacts/maintenance-photo-flow-adjustment/04-execution-initial.png`
- Locked after-photo capture: `/Users/starburst/Donesome/Hearthio/qa-artifacts/maintenance-photo-flow-adjustment/09-execution-bottom-locked.png`
- Unlocked after-photo capture: `/Users/starburst/Donesome/Hearthio/qa-artifacts/maintenance-photo-flow-adjustment/12-execution-bottom-unlocked.png`
- After-photo sheet capture: `/Users/starburst/Donesome/Hearthio/qa-artifacts/maintenance-photo-flow-adjustment/13-after-photo-sheet.png`
- Runtime viewport: iPhone 17 Pro simulator, iOS 26.5, 402 x 874 logical pixels at 3x density; captures are 1206 x 2622 pixels.
- Source dimensions: 853 x 1844 pixels. The initial implementation was proportionally resized to 853 x 1854 and center-cropped to 853 x 1844 for equal-size comparison.

## Comparison evidence

- Full source-left / initial implementation-right comparison: `/Users/starburst/Donesome/Hearthio/qa-artifacts/maintenance-photo-flow-adjustment/comparison-initial.png`
- Focused source-left / locked recording-surface-right comparison: `/Users/starburst/Donesome/Hearthio/qa-artifacts/maintenance-photo-flow-adjustment/comparison-recording-focus.png`
- Locked-left / unlocked-right implementation-state comparison: `/Users/starburst/Donesome/Hearthio/qa-artifacts/maintenance-photo-flow-adjustment/comparison-locked-unlocked.png`

## Required fidelity surfaces

- Fonts and typography: native iOS Chinese glyphs, weights, hierarchy, truncation, and line heights remain consistent with the selected direction and existing Hearthio screen. No cramped or broken copy is visible.
- Spacing and layout rhythm: the compact before-photo card adds one explicit pre-execution stage without disturbing the timeline. The former five-tile row becomes four wider record tiles, followed by a bounded comparison card; the fixed CTA remains clear of the bottom safe area.
- Colors and tokens: paper, canvas, forest, sage, divider, disabled gray, and active green use the existing Hearthio palette. Locked and unlocked states are visibly distinct without introducing a new color language.
- Image and icon quality: the purifier asset remains unchanged. Photo surfaces use the existing Material icon family and real photo thumbnails when available; no placeholder raster, emoji, custom SVG, or code-drawn substitute was introduced.
- Copy and content: `保养前留照（可选）`, `本次记录（可选）`, and `保养后留照（可选）` now describe separate stages. Locked copy explains why after capture is unavailable; unlocked copy explains the comparison purpose.
- Accessibility and interaction: both photo cards expose contextual semantic labels. Before-photo management locks after execution starts, after-photo management unlocks after every step completes, and the completion CTA remains independent of optional photos.

## Interaction and regression evidence

- Simulator interaction confirmed the initial before-photo card, the locked after-photo comparison state, automatic after-photo unlock after all four timeline steps, green completion CTA, and an after-only photo sheet.
- Widget tests verify the before-only and after-only sheets, locked add button after execution starts, delayed after-photo availability, independent before/after persistence, optional no-photo completion, timeline progression, and fixed action state.
- `flutter analyze` reports no issues. The full local Flutter suite passes 116 tests.
- Simulator evidence covers build, installation, launch, scrolling, step taps, state transitions, and screenshots. Physical-device, archive, TestFlight, and App Store evidence were not run.

## Findings and comparison history

- The prior implementation had a P1 information-architecture problem: a generic `照片` shortcut under `完成后记录` opened both before and after categories before any work began.
- The fix separates the stages, removes the generic aggregate photo shortcut, displays counts by side, and gates after capture on timeline completion.
- Post-fix full, focused, and state comparisons show no remaining actionable P0, P1, or P2 issue.
- [P3] Native Material camera/lock contours and Chinese glyph metrics differ slightly from ImageGen rendering.
- [P3] The explicit photo stages make the page longer than the original source, so the recording comparison card is reached by one natural scroll; this is an intentional hierarchy change requested by the user.

## Final result

passed
