# Operation benchmark reference

Baseline measurement for `mix benchmark.operations`. Keep this baseline and
add a single "Current" section after an intentional performance improvement;
replace that section on later improvements rather than keeping a run-by-run
history. Git history retains older measurements.

Measured on 2026-10-08, before changing PhoenixTest library code, using the
benchmark scenarios introduced by `Add mix benchmark.operations`.
macOS, Apple M3 (8 cores), Elixir 1.19.5, Erlang/OTP 27.0, JIT enabled.
The benchmark uses the bundled test app and `MIX_ENV=test`.

## Visits (not Benchee)

Both variants ran in the ExUnit process with the same timer, 10 warmups and 50
samples each, alternating order. LiveViewTest requires mounts in that process.
The timings include the request and, for LiveView, the mount. Different pages
and different underlying work mean the gap is not PhoenixTest-only overhead.

| Operation | Median | Mean |
| --- | ---: | ---: |
| Static `visit` | 37 μs | 43.2 μs |
| LiveView `visit` | 1,601 μs | 2,307.3 μs |

## Operations on existing sessions (Benchee)

1 s warmup and 2 s sampling per scenario, `parallel: 1`. Medians from the
initial run recorded in the benchmark's introducing commit:

| Operation | Static median | LiveView median |
| --- | ---: | ---: |
| `assert_has` | 89 μs | 350 μs |
| `fill_in` | 355.96 μs | 710 μs* |
| `select` | 438.04 μs | 1,630 μs |
| `check` | 418.63 μs | 1,580 μs |
| `choose` | 418 μs | 1,600 μs |
| `click_link` | 218.33 μs | — |
| `click_button` (submit) | 471.38 μs | — |
| `submit` | 219.25 μs | — |

* LiveView `fill_in` uses a form without a change event; other LiveView form
scenarios may include event handling. Benchee printed LiveView values in ms,
rounded to two decimal places; the μs values above reflect that precision.

Use each row as a before/after reference for the **same scenario on the same
machine**, preferably with repeated runs. Do not compare visit timings with
Benchee timings, or use cross-operation rankings alone to choose what to
optimize. These are end-to-end fixture timings, not isolated library overhead.
