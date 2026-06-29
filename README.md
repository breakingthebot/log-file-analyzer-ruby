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
3. Run `bundle install`.

## Environment Variables
No environment variables are required for iteration 1. See `.env.example`.

## Running Locally
1. Run `bundle exec ruby -Isrc exe/log-file-analyzer tests/fixtures/server.log`.
2. Run `bundle exec ruby -Isrc exe/log-file-analyzer --input-format json tests/fixtures/server.jsonl`.
3. Run `bundle exec ruby -Isrc exe/log-file-analyzer tests/fixtures/batch`.
4. Run `bundle exec ruby -Isrc exe/log-file-analyzer tests/fixtures/batch/common-a.log tests/fixtures/batch/common-b.log`.
5. Run `bundle exec ruby -Isrc exe/log-file-analyzer --format csv tests/fixtures/server.log`.
6. Run `bundle exec ruby -Isrc exe/log-file-analyzer --config .log-file-analyzer.yml`.
7. Optional filtered run: `bundle exec ruby -Isrc exe/log-file-analyzer --start-time 2026-06-29T10:00:01Z --end-time 2026-06-29T10:00:03Z tests/fixtures/server.log`.
8. Optional JSON report output: `bundle exec ruby -Isrc exe/log-file-analyzer --format json tests/fixtures/server.log`.

## Deployed
Not deployed. This is a local CLI tool.

## Architecture Notes
This build is a small command-line tool that takes a server log and turns it into something immediately useful: how many requests came in, how many failed, which kinds of requests they were, and which endpoints got hit the most. I split it into a parser, an analyzer, and a formatter so each part has one job, which makes the behavior easier to test and easier to extend later if the log format or output needs change.

In this iteration I added YAML config support so the CLI can carry team defaults without forcing long repeated commands. The merge order is explicit: built-in defaults first, then config values, then direct command-line flags. That gives repeatable shared behavior while still making one-off overrides straightforward.

## Notes
- The CLI supports `common`, `json`, and `auto` input modes.
- The CLI accepts one or more file paths, or a directory containing `.log` and `.jsonl` files.
- The CLI supports `text`, `json`, and `csv` output formats.
- The CLI can load defaults from `.log-file-analyzer.yml` or a custom path passed through `--config`.
- Time filters use inclusive ISO 8601 values such as `2026-06-29T10:00:00Z`.
- Reports include method counts, status-family counts, and exact status-code counts.
- Query strings are removed before endpoint aggregation so the same route is counted consistently.
- Malformed lines are skipped instead of crashing the whole analysis run.
