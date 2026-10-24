# Upstream bug: `scanimage --format=pdf` writes a broken cross-reference table

This is a report draft for the SANE project (`sane-devel` mailing list or
<https://gitlab.com/sane-project/backends>). It describes the bug that makes
scans look blank on macOS in this project's early versions.

## Summary

On macOS, PDFs written by `scanimage --format=pdf` (SANE 1.4.0) have an invalid
cross-reference table: every entry is `0000000000 00000 n` and `startxref` is
`0`. CoreGraphics (Preview, Quick Look, PDFKit) reports
`CoreGraphics PDF has logged an error` and renders a blank page. The embedded
image stream itself is intact and decodes correctly.

## Environment

- macOS 26.6.2 (25G83), Apple M5 (arm64)
- sane-backends 1.4.0 (Homebrew)
- Backend: `pixma` (Canon imageCLASS MF4010, USB)
- Tested modes: Gray/Color, 75–600 dpi

## Reproduction

```sh
scanimage -d pixma:04A926B4_<serial> --format=pdf --resolution=300 \
          --mode=Gray -o scan.pdf
```

## Observed

- `scan.pdf` ends with a valid-looking `trailer << /Size 9 /Root 1 0 R /Info 3 0 R >>`
  and `%%EOF`, but the xref table entries are all zeros and `startxref` is `0`.
- The `/DCTDecode` image object contains a complete JPEG (2560×3508).
- Extracting that JPEG and viewing it shows the scanned page correctly.
- Quick Look / Preview show a blank white page and log a CoreGraphics PDF error.
- `sips -s format png scan.pdf` produces a fully transparent image, consistent
  with a parse failure.

## Expected

A valid xref table and a correct `startxref` offset so standard PDF readers can
open the file without repair.

## Workaround used by this project

Scan to PNG and build the PDF with macOS ImageIO (`sips -s format pdf`), which
writes a correct xref; or use any other PDF writer.

## Notes

Possibly the PDF writer in `scanimage` does not record object offsets (writes
zeroes) and relies on readers repairing the file. Linux viewers such as
poppler/mupdf often do repair silently, while CoreGraphics does not.
