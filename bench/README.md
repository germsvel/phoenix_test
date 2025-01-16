# Performance Benchmarks

Performance benchmarks are run using [benchee](https://github.com/bencheeorg/benchee).

Run a benchmark with `MIX_ENV=test mix run <benchmark-file-name>`, for example
`MIX_ENV=test mix run bench/assertions.exs`. We use the `test` environment so
that benchmarks have access to the same testing LiveView application used by
unit tests.
