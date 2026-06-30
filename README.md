# Log File Analyzer

Reads common server access logs or newline-delimited JSON logs and reports request counts, error rates, method breakdowns, status breakdowns, and top endpoints from the command line.

## Stack
- Ruby 3.4
- Ruby standard library: `optparse`, `logger`, `json`, `time`
- Minitest for tests
- GitHub Actions for CI

## Setup
1. Install Ruby 3.4 or later.
2. Clone the repository.
3. Confirm your local Ruby matches `.ruby-version` if you use a version manager.
4. Run `ruby bin/setup`.

## Environment Variables
No environment variables are required for iteration 1. See `.env.example`.

## Running Locally
1. Check the packaged version with `ruby exe/log-file-analyzer --version`.
2. Run `ruby exe/log-file-analyzer tests/fixtures/server.log`.
3. Run `ruby exe/log-file-analyzer --input-format json tests/fixtures/server.jsonl`.
4. Run `ruby exe/log-file-analyzer tests/fixtures/batch`.
5. Run `ruby exe/log-file-analyzer tests/fixtures/batch/common-a.log tests/fixtures/batch/common-b.log`.
6. Run `ruby exe/log-file-analyzer --format csv tests/fixtures/server.log`.
7. Run `ruby exe/log-file-analyzer --config .log-file-analyzer.yml`.
8. Run `ruby exe/log-file-analyzer --time-bucket minute tests/fixtures/server.log`.
9. Run `ruby exe/log-file-analyzer --time-bucket minute --time-bucket-series method tests/fixtures/server.log`.
10. Run `ruby exe/log-file-analyzer --format csv --output tmp/report.csv tests/fixtures/server.log`.
11. Optional filtered run: `ruby exe/log-file-analyzer --start-time 2026-06-29T10:00:01Z --end-time 2026-06-29T10:00:03Z tests/fixtures/server.log`.
12. Run `ruby exe/log-file-analyzer tests/fixtures/batch/mixed/common-mixed.data tests/fixtures/batch/mixed/json-mixed.data`.
13. Optional JSON report output: `ruby exe/log-file-analyzer --format json tests/fixtures/server.log`.
14. Run `ruby exe/log-file-analyzer tests/fixtures/server.log.gz`.
15. Run `ruby exe/log-file-analyzer --max-error-rate 30 tests/fixtures/server.log` to exercise threshold failure behavior.
16. Run the full automated suite with `ruby bin/test` to execute every file under `tests/`.

## Installing The Packaged CLI
1. Run `ruby bin/install`.
2. Run the installed command from `tmp/bin/log-file-analyzer --version` on macOS/Linux or `tmp\bin\log-file-analyzer.bat --version` on Windows.
3. Run the installed command against a fixture log, for example `tmp\bin\log-file-analyzer.bat tests\fixtures\server.log` on Windows.
4. Remove the repo-local install with `ruby bin/uninstall`.

## Deployed
Not deployed. This is a local CLI tool.

## Architecture Notes
This build is a small command-line tool that takes a server log and turns it into something immediately useful: how many requests came in, how many failed, which kinds of requests they were, and which endpoints got hit the most. I split it into a parser, an analyzer, and a formatter so each part has one job, which makes the behavior easier to test and easier to extend later if the log format or output needs change.

In this iteration I added direct file output so the analyzer can participate in scripted workflows without shell redirection. The CLI now keeps stdout as the default, but it can also write the rendered report straight to a requested path, which makes CSV and JSON exports much easier to schedule or hand off to another step in a pipeline.

The next pass added multi-series time buckets so each trend interval can explain what drove the change, not just how large the bucket was. The CLI now supports method or status-family series inside each bucket, which makes trend output much more useful during incident review because it can show whether a spike was mostly `POST` traffic, mostly 5xx responses, or something else entirely.

This iteration tightened the install and handoff story so a fresh clone behaves more like a normal Ruby CLI project instead of a one-off script. The repo now ships with a standard setup command, a single test entry point, a pinned Ruby version file, and a version flag that matches the actual release state, which makes local onboarding, CI, and portfolio demos much less error-prone.

This pass added a real packaged install demo path without touching the machine's global gem state. The project can now build itself, install into repo-local `tmp/` directories, run as an installed command, and clean itself up again, which makes the gem story much easier to show in an interview or hand to someone reviewing the repo.

This iteration added gzip support so the same CLI can read archived `.log.gz` and `.jsonl.gz` files without a manual decompression step first. That keeps the parser, detector, and path resolver separate, but lets the tool fit the way teams usually store rotated logs in real environments.

This pass added automation thresholds so the tool can do more than print a report and exit successfully every time. It can now fail with a distinct exit code when error rate, total error volume, or 5xx volume crosses a configured limit, which makes the CLI useful in CI jobs, scheduled checks, and scripted release validation.

## Notes
- The CLI supports `common`, `json`, and `auto` input modes.
- The repo includes `ruby bin/setup` for dependency bootstrap and `ruby bin/test` for the full test suite.
- The repo includes `ruby bin/install` and `ruby bin/uninstall` for a repo-local packaged CLI workflow.
- The CLI accepts `.log`, `.jsonl`, `.log.gz`, and `.jsonl.gz` inputs.
- The CLI accepts one or more file paths, or a directory containing supported plain-text or gzip-compressed log files.
- The CLI supports `--max-error-rate`, `--max-error-requests`, and `--max-5xx-requests` for threshold-based automation failures.
- The CLI supports `text`, `json`, and `csv` output formats.
- The CLI can load defaults from `.log-file-analyzer.yml` or a custom path passed through `--config`.
- Config files reject unsupported keys and invalid option values with explicit errors.
- The CLI supports `--time-bucket none|minute|hour` for trend summaries.
- The CLI supports `--time-bucket-series none|method|status-family` for per-bucket breakdowns.
- The CLI supports `--version` and now reports the current packaged release version.
- Auto input mode detects format per file inside batch runs.
- The CLI supports `--output PATH` to write the rendered report directly to disk.
- Time filters use inclusive ISO 8601 values such as `2026-06-29T10:00:00Z`.
- Reports include method counts, status-family counts, and exact status-code counts.
- Query strings are removed before endpoint aggregation so the same route is counted consistently.
- Malformed lines are skipped instead of crashing the whole analysis run.
