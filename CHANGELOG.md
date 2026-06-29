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

## [0.5.0] - 2026-06-29

- Add batch analysis for multiple input files and directories.
- Expand directories into sorted supported log files (`.log` and `.jsonl`) and deduplicate repeated paths.
- Add parser and path-resolution coverage for combined file processing.

## [0.6.0] - 2026-06-29

- Add CSV output support through `--format csv`.
- Export summary metrics, breakdown sections, and top endpoints in a machine-friendly row format.
- Add formatter coverage for CSV rendering.

## [0.7.0] - 2026-06-29

- Add YAML config-file support for default CLI options.
- Define precedence as built-in defaults, then config values, then explicit CLI flags.
- Add loader and option-merging coverage for config-backed runs.

## [0.8.0] - 2026-06-29

- Add time-bucket summaries with `none`, `minute`, and `hour` modes.
- Extend text, JSON, and CSV output to include chronological request/error bucket rows.
- Add analyzer, formatter, config, and CLI coverage for trend summaries.

## [0.9.0] - 2026-06-29

- Add file-level format detection for mixed batch parsing in auto mode.
- Detect parser modes from file extension first, then from sampled content when needed.
- Add detector and mixed-batch coverage for common and JSON files with nonstandard extensions.
