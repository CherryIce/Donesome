# LAURUS App Store previews

This folder contains five English marketing screenshots composed from the five
physical-device captures supplied on 2026-08-24.

## Output sets

- `final/iphone-6.5/`: 1242 × 2688 portrait PNGs.
- `final/ipad-13/`: 2064 × 2752 portrait PNGs.

All output files are opaque RGB PNGs. The original captures remain in `source/`.
The generator replaces the old brand copy visible on the Home and Settings
screens in the final composites and draws the current LAURUS app icon and name
above each screenshot. The `qa/` contact sheets are generated from the final
outputs.

## Regenerate

From the project root:

```sh
python3 tool/generate_app_store_previews.py
```

## Submission evidence boundary

The iPhone set is derived from physical iPhone captures with the two visible
brand references updated for LAURUS. The iPad-sized set is a marketing layout
derived from those same iPhone captures, not a native iPad capture. Before
treating the iPad set as final App Store evidence, replace its screen layer with
captures from the exact 13-inch iPad build being submitted.

The images have been prepared locally and have not been uploaded to App Store
Connect.

Apple reference:
<https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/>
