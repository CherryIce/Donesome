#!/usr/bin/env python3
"""Build Hearthio App Store preview artwork from the supplied device captures."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps


ROOT = Path(__file__).resolve().parents[1]
ARTIFACTS = ROOT / "artifacts" / "app-store-previews"
SOURCE_DIR = ARTIFACTS / "source"
BACKGROUND = ARTIFACTS / "backgrounds" / "hearthio-brand-background.png"
APP_ICON = (
    ROOT
    / "ios"
    / "Runner"
    / "Assets.xcassets"
    / "AppIcon.appiconset"
    / "Icon-App-1024x1024@1x.png"
)
FONT_PATH = Path("/System/Library/Fonts/SFNS.ttf")


@dataclass(frozen=True)
class Preview:
    source: str
    output: str
    title: str
    subtitle: str


@dataclass(frozen=True)
class Layout:
    canvas_size: tuple[int, int]
    final_dir: Path
    screenshot_width: int
    screenshot_y: int
    crop_height: int | None
    corner_radius: int
    shadow_blur: int
    brand_y: int
    brand_icon: int
    title_y: int
    title_size: int
    subtitle_y: int
    subtitle_size: int
    side_margin: int


PREVIEWS = (
    Preview(
        source="01-home.jpg",
        output="01-todays-care-at-a-glance.png",
        title="Today’s Care,\nClear at a Glance",
        subtitle="See what’s due and start with the most urgent task.",
    ),
    Preview(
        source="02-items.jpg",
        output="02-every-item-organized.png",
        title="Every Item,\nOrganized",
        subtitle="Keep care plans, spaces, and categories together.",
    ),
    Preview(
        source="03-schedule.jpg",
        output="03-one-care-calendar.png",
        title="Your Care Plan,\nOn One Calendar",
        subtitle="See upcoming maintenance and what needs attention.",
    ),
    Preview(
        source="04-reports.jpg",
        output="04-real-records-useful-reports.png",
        title="Real Records.\nUseful Reports.",
        subtitle="Understand completed care, overdue tasks, and actual costs.",
    ),
    Preview(
        source="05-settings.jpg",
        output="05-private-and-portable.png",
        title="Private by Design.\nPortable by Choice.",
        subtitle="Local reminders, CSV export, and full backup stay in your control.",
    ),
)


IPHONE_65 = Layout(
    canvas_size=(1242, 2688),
    final_dir=ARTIFACTS / "final" / "iphone-6.5",
    screenshot_width=920,
    screenshot_y=688,
    crop_height=None,
    corner_radius=58,
    shadow_blur=42,
    brand_y=66,
    brand_icon=66,
    title_y=190,
    title_size=88,
    subtitle_y=446,
    subtitle_size=34,
    side_margin=82,
)


IPAD_13 = Layout(
    canvas_size=(2064, 2752),
    final_dir=ARTIFACTS / "final" / "ipad-13",
    screenshot_width=1540,
    screenshot_y=620,
    crop_height=1490,
    corner_radius=68,
    shadow_blur=56,
    brand_y=64,
    brand_icon=78,
    title_y=180,
    title_size=116,
    subtitle_y=490,
    subtitle_size=43,
    side_margin=126,
)


def sf_font(size: int, weight: int) -> ImageFont.FreeTypeFont:
    font = ImageFont.truetype(str(FONT_PATH), size=size)
    try:
        font.set_variation_by_axes(
            [100, min(max(size, 17), 96), max(weight - 80, 400), weight]
        )
    except (AttributeError, OSError):
        pass
    return font


def flatten(image: Image.Image, background=(248, 245, 237)) -> Image.Image:
    source = image.convert("RGBA")
    result = Image.new("RGB", source.size, background)
    result.paste(source, mask=source.getchannel("A"))
    return result


def rounded_asset(path: Path, size: int, radius: int) -> Image.Image:
    source = ImageOps.fit(
        flatten(Image.open(path)),
        (size, size),
        method=Image.Resampling.LANCZOS,
    )
    mask = Image.new("L", source.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, size - 1, size - 1), radius=radius, fill=255
    )
    result = Image.new("RGBA", source.size, (0, 0, 0, 0))
    result.paste(source, mask=mask)
    return result


def add_top_contrast(canvas: Image.Image) -> None:
    fade_height = round(canvas.height * 0.26)
    overlay = Image.new("RGBA", canvas.size, (15, 48, 38, 0))
    alpha = Image.new("L", canvas.size, 0)
    draw = ImageDraw.Draw(alpha)
    for y in range(fade_height):
        opacity = round(124 * (1 - y / fade_height) ** 1.45)
        draw.line((0, y, canvas.width, y), fill=opacity)
    overlay.putalpha(alpha)
    canvas.alpha_composite(overlay)


def add_brand(canvas: Image.Image, layout: Layout, index: int) -> None:
    x = layout.side_margin
    icon = rounded_asset(APP_ICON, layout.brand_icon, round(layout.brand_icon * 0.23))
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow_mask = Image.new("L", canvas.size, 0)
    ImageDraw.Draw(shadow_mask).rounded_rectangle(
        (
            x,
            layout.brand_y + 5,
            x + layout.brand_icon,
            layout.brand_y + layout.brand_icon + 5,
        ),
        radius=round(layout.brand_icon * 0.23),
        fill=105,
    )
    shadow_mask = shadow_mask.filter(ImageFilter.GaussianBlur(13))
    shadow.paste((0, 20, 14, 125), mask=shadow_mask)
    canvas.alpha_composite(shadow)
    canvas.alpha_composite(icon, (x, layout.brand_y))

    draw = ImageDraw.Draw(canvas)
    brand_size = round(layout.brand_icon * 0.46)
    draw.text(
        (
            x + layout.brand_icon + round(layout.brand_icon * 0.25),
            layout.brand_y + round(layout.brand_icon * 0.16),
        ),
        "Hearthio",
        font=sf_font(brand_size, 680),
        fill=(255, 255, 255, 255),
    )

    number_text = f"{index:02d}"
    number_font = sf_font(round(layout.brand_icon * 0.37), 650)
    number_bbox = draw.textbbox((0, 0), number_text, font=number_font)
    number_width = number_bbox[2] - number_bbox[0]
    pill_width = number_width + round(layout.brand_icon * 0.72)
    pill_height = round(layout.brand_icon * 0.68)
    pill_x = canvas.width - layout.side_margin - pill_width
    pill_y = layout.brand_y + round((layout.brand_icon - pill_height) / 2)
    draw.rounded_rectangle(
        (pill_x, pill_y, pill_x + pill_width, pill_y + pill_height),
        radius=pill_height // 2,
        fill=(29, 74, 59, 210),
        outline=(255, 255, 255, 105),
        width=2,
    )
    draw.text(
        (pill_x + (pill_width - number_width) / 2, pill_y + round(pill_height * 0.13)),
        number_text,
        font=number_font,
        fill=(248, 245, 237, 255),
    )


def wrap_text(
    draw: ImageDraw.ImageDraw,
    text: str,
    font: ImageFont.FreeTypeFont,
    max_width: int,
) -> str:
    words = text.split()
    lines: list[str] = []
    current = ""
    for word in words:
        candidate = word if not current else f"{current} {word}"
        if draw.textlength(candidate, font=font) <= max_width:
            current = candidate
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return "\n".join(lines)


def add_copy(canvas: Image.Image, layout: Layout, preview: Preview) -> None:
    draw = ImageDraw.Draw(canvas)
    x = layout.side_margin
    accent_width = 72 if canvas.width < 1500 else 108
    accent_height = 8 if canvas.width < 1500 else 11
    accent_y = layout.title_y - (29 if canvas.width < 1500 else 34)
    draw.rounded_rectangle(
        (x, accent_y, x + accent_width, accent_y + accent_height),
        radius=accent_height // 2,
        fill=(231, 139, 76, 255),
    )
    draw.multiline_text(
        (x, layout.title_y),
        preview.title,
        font=sf_font(layout.title_size, 790),
        fill=(255, 255, 255, 255),
        spacing=4 if canvas.width < 1500 else 7,
    )
    subtitle_font = sf_font(layout.subtitle_size, 510)
    subtitle = wrap_text(
        draw,
        preview.subtitle,
        subtitle_font,
        canvas.width - layout.side_margin * 2,
    )
    draw.multiline_text(
        (x, layout.subtitle_y),
        subtitle,
        font=subtitle_font,
        fill=(225, 236, 228, 255),
        spacing=8,
    )


def screenshot_panel(
    source_path: Path,
    target_width: int,
    crop_height: int | None,
    radius: int,
    shadow_blur: int,
) -> tuple[Image.Image, Image.Image]:
    source = flatten(Image.open(source_path), background=(247, 248, 243))
    if crop_height is not None:
        source = source.crop((0, 0, source.width, min(crop_height, source.height)))
    target_height = round(source.height * target_width / source.width)
    source = source.resize((target_width, target_height), Image.Resampling.LANCZOS)

    mask = Image.new("L", source.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, source.width - 1, source.height - 1), radius=radius, fill=255
    )
    panel = Image.new("RGBA", source.size, (0, 0, 0, 0))
    panel.paste(source, mask=mask)
    ImageDraw.Draw(panel).rounded_rectangle(
        (1, 1, panel.width - 2, panel.height - 2),
        radius=radius,
        outline=(255, 255, 255, 170),
        width=4,
    )

    shadow_margin = shadow_blur * 2
    shadow = Image.new(
        "RGBA",
        (panel.width + shadow_margin * 2, panel.height + shadow_margin * 2),
        (0, 0, 0, 0),
    )
    shadow_mask = Image.new("L", shadow.size, 0)
    ImageDraw.Draw(shadow_mask).rounded_rectangle(
        (
            shadow_margin,
            shadow_margin + round(shadow_blur * 0.30),
            shadow_margin + panel.width,
            shadow_margin + panel.height + round(shadow_blur * 0.30),
        ),
        radius=radius,
        fill=145,
    )
    shadow_mask = shadow_mask.filter(ImageFilter.GaussianBlur(shadow_blur))
    shadow.paste((17, 48, 37, 155), mask=shadow_mask)
    return panel, shadow


def compose(layout: Layout, preview: Preview, index: int) -> Path:
    centering = (0.5, 0.5) if layout.canvas_size[0] < 1500 else (0.5, 0.18)
    background = ImageOps.fit(
        flatten(Image.open(BACKGROUND)),
        layout.canvas_size,
        method=Image.Resampling.LANCZOS,
        centering=centering,
    )
    canvas = background.convert("RGBA")
    add_top_contrast(canvas)
    add_brand(canvas, layout, index)
    add_copy(canvas, layout, preview)

    panel, shadow = screenshot_panel(
        SOURCE_DIR / preview.source,
        layout.screenshot_width,
        layout.crop_height,
        layout.corner_radius,
        layout.shadow_blur,
    )
    frame_x = (canvas.width - panel.width) // 2
    margin = layout.shadow_blur * 2
    canvas.alpha_composite(
        shadow,
        (frame_x - margin, layout.screenshot_y - margin),
    )
    canvas.alpha_composite(panel, (frame_x, layout.screenshot_y))

    layout.final_dir.mkdir(parents=True, exist_ok=True)
    output = layout.final_dir / preview.output
    canvas.convert("RGB").save(output, format="PNG", optimize=True)
    return output


def main() -> None:
    required = [BACKGROUND, APP_ICON, *(SOURCE_DIR / item.source for item in PREVIEWS)]
    missing = [path for path in required if not path.exists()]
    if missing:
        missing_text = "\n".join(str(path) for path in missing)
        raise FileNotFoundError(f"Missing preview inputs:\n{missing_text}")

    outputs = [
        compose(layout, preview, index)
        for layout in (IPHONE_65, IPAD_13)
        for index, preview in enumerate(PREVIEWS, start=1)
    ]
    for output in outputs:
        print(output.relative_to(ROOT))


if __name__ == "__main__":
    main()
