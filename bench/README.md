# Performance Benchmarks

Performance benchmarks are run using [benchee](https://github.com/bencheeorg/benchee).

Run a benchmark with `MIX_ENV=test mix run <benchmark-file-name>`, for example
`MIX_ENV=test mix run bench/assertions.exs`. We use the `test` environment so
that benchmarks have access to the same testing LiveView application used by
unit tests.

Run `mix benchmark.operations` to compare representative public operations on
static pages and LiveViews. The script uses Benchee for operations that can run
in a worker process (1 s warmup, 2 s sampling). Both `visit/2` variants are
sampled with the same timer in the ExUnit process (10 warmups + 50 calls each,
alternating order), because LiveViewTest requires mounts to run there. Compare
these two visit numbers with each other, not with the Benchee numbers. Visits
include request/mount time; other operations start with an existing session.
Form benchmarks target the bundled example app, and LiveView form inputs can
include `phx-change` handling. Results are machine- and fixture-dependent;
compare before/after runs on the same machine. The initial measurements are
recorded in [RESULTS.md](RESULTS.md); retain that baseline and add or update
one current-result section after an improvement.
