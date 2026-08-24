# Hearthio App Store previews

This folder contains five English marketing screenshots composed from the five
physical-device captures supplied on 2026-08-24.

## Output sets

- `final/iphone-6.5/`: 1242 × 2688 portrait PNGs.
- `final/ipad-13/`: 2064 × 2752 portrait PNGs.

All output files are opaque RGB PNGs. The app UI is preserved from the supplied
captures; the generated asset is used only as the surrounding background.

## Regenerate

From the project root:

```sh
python3 tool/generate_app_store_previews.py
```

## Submission evidence boundary

The iPhone set is derived from physical iPhone captures. The iPad-sized set is a
marketing layout derived from those same iPhone captures, not a native iPad
capture. Before treating the iPad set as final App Store evidence, replace its
screen layer with captures from the exact 13-inch iPad build being submitted.

The images have been prepared locally and have not been uploaded to App Store
Connect.

Apple reference:
<https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/>
