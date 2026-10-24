# Canon MF4010 scanning on modern macOS

[![CI](https://github.com/zvdenis/canon-mf4010-macos/actions/workflows/ci.yml/badge.svg)](https://github.com/zvdenis/canon-mf4010-macos/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Get a Canon imageCLASS MF4010 scanning again on macOS 12+ — Apple Silicon
included — where Canon's own ScanGear driver no longer runs.

## Why this exists

Canon's scanner driver for the MF4010 is 32-bit Intel code. macOS dropped 32-bit
apps in Catalina, and there is no Apple Silicon build, so Image Capture, Preview
and the system "Scan" feature never see the device. Printing still works through
Canon's UFR II driver; only scanning is dead.

The hardware itself is fine: SANE's `pixma` backend supports the MF4010 over USB.
This project turns that into a usable `scan` command and a Spotlight app, and
works around a `scanimage` PDF bug that otherwise produces blank white pages on
macOS.

## What you get

- **`scan`** — one command, sensible defaults (A4, 300 dpi, grayscale, PDF).
- **Scan.app** — press ⌘Space, type `Scan`, Return; the PDF opens in Preview.
- **`install.sh` / `uninstall.sh`** — no sudo, no kernel extensions.

## Requirements

- macOS (tested on 26.6.2 with an Apple M5; Intel Macs should work too)
- [Homebrew](https://brew.sh)
- The printer connected over USB

## Install

### One-liner

```sh
curl -fsSL https://raw.githubusercontent.com/zvdenis/canon-mf4010-macos/main/install.sh | bash
```

The installer installs SANE via Homebrew if needed, puts `scan` in your Homebrew
`bin`, and builds `Scan.app` in `/Applications` (or `~/Applications` if that
isn't writable).

### From a clone

```sh
git clone https://github.com/zvdenis/canon-mf4010-macos.git
cd canon-mf4010-macos
./install.sh
```

Options: `--prefix DIR`, `--app-dir DIR`, `--no-app`, `--no-brew`.

## Use

### Spotlight and Finder

⌘Space → type `Scan` → Return. It scans one page, saves it to
`~/Documents/Scans`, and opens it in Preview. Put the page **face-down on the
glass** first — scanning starts immediately.

### Command line

```sh
scan                    # 300 dpi grayscale PDF -> ~/Documents/Scans
scan -c                 # color
scan -c -r 150          # fast color draft
scan -l -n Receipt      # black & white, custom file name
scan -p 3               # 3 pages, prompts you to swap pages
scan --png -o ~/Desktop/page.png
scan --list             # show detected scanners
scan --version
```

Defaults: full A4 bed, 300 dpi, grayscale, PDF, named
`Scan-YYYY-MM-DD-HHMMSS.pdf`, opened in Preview. Use `--no-open` to skip
opening, `-o FILE` for an exact path, and `SCAN_DIR` to change the folder.

## The blank-page bug this works around

`scanimage --format=pdf` in SANE 1.4.0 writes a PDF whose cross-reference table
is all zeros, with `startxref 0`. The scanned image is inside the file and valid,
but CoreGraphics (Preview, Quick Look, PDFKit) refuses to draw it and logs:

```
CoreGraphics PDF has logged an error
```

The page then looks blank white. Other readers may silently repair the file,
which makes the problem look intermittent. `scan` therefore scans a lossless PNG
and builds the PDF with macOS ImageIO (`sips`), which writes a correct xref. See
[docs/upstream-report.md](docs/upstream-report.md) for the upstream write-up.

## Troubleshooting

| Symptom | What to do |
|---|---|
| `scan: no Canon scanner found` | Printer off or asleep — press a button on it, check the USB cable, run `scan --list`. |
| Page is white in Preview | Make sure the sheet is face-down on the glass. PDFs created before 0.1.0 were malformed — scan again with the current version. |
| Scan hangs / device busy | Unplug and replug USB, wait ~10 s, retry. Long print jobs share the USB link. |
| Streaks or gray background | Clean the platen glass. |
| App seems to do nothing | Check `/tmp/scan-app.log`; run `scan` in Terminal to see the error. |

## Uninstall

```sh
./uninstall.sh
```

Removes `scan` and `Scan.app`; your scans in `~/Documents/Scans` are untouched.
To remove the driver as well: `brew uninstall sane-backends`.

## How it works

- `scanimage` drives the scanner through SANE's `pixma` backend
  (`pixma:04A926B4_<serial>`).
- `scan` scans to PNG, converts to PDF with `sips` (macOS ImageIO), and opens the
  result.
- `Scan.app` is a small AppleScript applet that runs `scan` and shows a dialog if
  it fails.

Tested against a Canon imageCLASS MF4010 Series over USB, macOS 26.6.2 (25G83),
Apple M5, SANE 1.4.0, and Canon UFR II 10.19.25 for printing. Other Canon MFPs
listed in `man sane-pixma` (MF4018, MF4120, MF4150, ...) will likely work, but
only the MF4010 has been tested.

Not affiliated with Canon. SANE is GPL-2.0; this wrapper is MIT.

## License

MIT — see [LICENSE](LICENSE).
