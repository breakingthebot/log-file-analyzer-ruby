# Changelog

## [0.1.0] - 2026-06-29

- Bootstrap the Ruby log file analyzer project.
- Add a CLI that reads common access logs and reports request counts, error totals, error rate, and top endpoints.
- Add Minitest coverage for parsing, aggregation, and report formatting.
- Add GitHub Actions CI and an MIT license.

## [0.2.0] - 2026-06-29

- Add `--input-format` support with `auto`, `common`, and `json` modes.
- Split line parsing into format-specific parser classes to keep parsing modular.
- Add newline-delimited JSON log fixtures and parser coverage for structured logs.
