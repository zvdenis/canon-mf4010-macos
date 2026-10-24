# Changelog

## 0.1.0 — 2026-10-24

- Initial release.
- `scan` command: PDF/PNG/JPEG/TIFF output, 75–600 dpi, color/gray/lineart,
  single page or prompted multi-page, auto-detected SANE device.
- `Scan.app` for Spotlight/Finder: one page, defaults, opens in Preview.
- PDFs are built from lossless PNG via macOS ImageIO, working around
  `scanimage`'s broken PDF cross-reference table (blank white pages).
- `install.sh` (local or `curl | bash`) and `uninstall.sh`.
