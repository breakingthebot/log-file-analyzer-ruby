# Log File Analyzer

Reads common server access logs and reports request counts, error rates, and top endpoints from the command line.

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
2. Optional JSON output: `bundle exec ruby -Isrc exe/log-file-analyzer --format json tests/fixtures/server.log`.

## Deployed
Not deployed. This is a local CLI tool.

## Architecture Notes
This build is a small command-line tool that takes a plain server log and turns it into something immediately useful: how many requests came in, how many failed, and which endpoints got hit the most. I split it into a parser, an analyzer, and a formatter so each part has one job, which makes the behavior easier to test and easier to extend later if the log format or output needs change.

I also kept the first iteration dependency-light on purpose. The standard library already covers argument parsing, logging, and JSON, so the project starts fast, stays easy to audit, and has fewer moving parts in CI.

## Notes
- Iteration 1 supports common Apache and Nginx-style access log lines.
- Query strings are removed before endpoint aggregation so the same route is counted consistently.
- Malformed lines are skipped instead of crashing the whole analysis run.
