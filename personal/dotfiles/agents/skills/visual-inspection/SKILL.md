---
name: visual-inspection
description: Inspect screenshots, photos, diagrams, scans, PDFs and video frames with an overview, targeted crops, optional local OCR and verification. Load before making visual claims or checking a UI's appearance. Covers existing browser tools, user-provided desktop screenshots, ImageMagick and Tesseract without assuming every machine has the same tools or permissions.
---

# Visual inspection

Get enough visual evidence to answer the question, without treating a thumbnail or OCR result as the whole picture. Tools improve the evidence available to the model; they don't make uncertain details certain.

## Choose the smallest useful source

- Existing images and PDFs: use the harness's image/PDF viewer. If PDFs aren't supported, render only the relevant pages with an available PDF renderer. Tesseract takes images, not PDF input.
- Browser: use the connected browser's accessibility snapshot for text and controls, and a screenshot for appearance. A DOM tree doesn't prove what the page looks like. Prefer an element screenshot for a specific detail, or native device scale when small text matters.
- macOS desktop: prefer a screenshot the user explicitly supplies. Shift-Command-4, then Space, lets the user select one window; Shift-Command-5 opens Screenshot with capture and save-location options. Automated desktop capture needs both user authorisation and any applicable workplace approval. A built-in command or connected MCP server is not proof of approval.
- Phone: follow the user's phone-access and claim/release rules before interacting. Prefer the UI hierarchy for controls and screenshots for visual details.
- Video: inspect a bounded set of timestamped frames using an available video tool, such as FFmpeg. Sample more closely around the relevant event; don't claim sampled frames prove what happened between them.

Prefer a named window or region over the whole desktop. Don't start continuous recording or a camera feed just because capture is available. Avoid capturing unrelated messages, credentials or other private windows. Local capture and OCR do not mean the model is local: images opened in a hosted harness are sent to that service.

## Inspect, crop, then verify

1. Open an overview. Establish orientation, dimensions and the area relevant to the question.
2. Inspect relevant regions at native resolution. Crop or tile a large image rather than shrinking tiny text into one overview. Keep enough overlap to preserve context and note each crop's source coordinates.
3. Use OCR only where text extraction helps. Check important numbers, names and labels against the actual pixels and report anything illegible.
4. For UI checks, pair the screenshot with the DOM/accessibility evidence where available. Use fresh element IDs rather than guessed coordinates. A screenshot's physical pixels can differ from the desktop's logical points, especially on Retina displays. User-provided desktop screenshots alone do not expose actionable UI elements.
5. If an authorised action changes the UI, capture the same target again and verify the result. A successful input call alone doesn't prove success.
6. Separate what is visible from what is inferred. Cite the file, page, window or frame timestamp. If the detail still isn't clear, ask for a better source instead of inventing it.

Don't use generative upscaling, heavy sharpening or thresholding as proof of missing detail. Preprocessing is a second view; keep the original and compare it.

## Respect capture restrictions

If endpoint security blocks a capture or automation tool, stop using it. Don't rename, re-sign, repackage, downgrade or switch launch methods to get around the block. Don't replace it with another automation tool until the relevant policy permits that use.

User consent, macOS Screen Recording/Accessibility permissions and workplace approval are separate requirements. Ask the user to grant missing OS permissions through the normal UI when the intended use is approved; don't change security controls or infer approval from a successful launch. Use an approved capture workflow or ask the user for an image they are permitted to share.

## ImageMagick and Tesseract

Check `command -v magick`, `command -v tesseract`, and `tesseract --list-langs` before assuming availability. Keep temporary files inside the allowed workspace, prefix them with `tmp_rovo_`, and remove only files created for the current task. Don't overwrite the source image.

Example crop and OCR commands (set the input and region from the actual image):

```sh
INPUT="path/to/image.png"
CROP_GEOMETRY="800x600+120+240"
CROP="tmp_rovo_visual_crop.png"
OCR_LANGUAGE="eng"
OCR_SINGLE_BLOCK=6

magick identify "$INPUT"
magick "$INPUT" -crop "$CROP_GEOMETRY" +repage "$CROP"
tesseract "$CROP" stdout -l "$OCR_LANGUAGE" --psm "$OCR_SINGLE_BLOCK"
```

Choose the segmentation mode to match the source: `3` for a page, `6` for one text block, `7` for a single line, or `11` for scattered UI text. These are Tesseract's mode IDs, not accuracy settings. Use `tsv` output when word boxes and confidence scores help locate uncertain text; confidence isn't a guarantee.

Use `chi_tra` for Traditional Chinese or `chi_sim` for Simplified Chinese only if listed by `--list-langs`; combine with `eng` for mixed text. OCR recognises written characters, not Cantonese pronunciation. Don't silently substitute English-only recognition for Chinese text.

For before/after checks, use the same viewport, scale, crop and application state. Pixel differences can come from animation or font rendering, so inspect a difference image rather than treating every changed pixel as a defect.

## References

- [Apple screenshot controls](https://support.apple.com/en-au/102646)
- [ImageMagick command-line processing](https://imagemagick.org/command-line-processing/)
- [Tesseract command-line usage](https://tesseract-ocr.github.io/tessdoc/Command-Line-Usage.html)
