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
