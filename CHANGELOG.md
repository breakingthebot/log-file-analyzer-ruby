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

## [0.3.0] - 2026-06-29

- Add `--start-time` and `--end-time` filters using inclusive ISO 8601 windows.
- Parse timestamps from both common access logs and JSON log lines.
- Add dedicated tests for time-window validation and filtering.

## [0.4.0] - 2026-06-29

- Add request breakdowns by HTTP method, status family, and exact status code.
- Extend text and JSON reports to expose the new breakdown sections.
- Add analyzer and formatter coverage for the richer summary structure.
