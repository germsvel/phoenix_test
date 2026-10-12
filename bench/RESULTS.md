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

## Additional scenarios (baseline extension, before library changes)

These scenarios were added after the initial commit. LiveView scenarios use
separate mounted sessions so one event cannot change another scenario's input.
Median timings from the same machine and runtime, with the same Benchee settings:

| Operation | Median |
| --- | ---: |
| LiveView `click_link` (patch) | 739.21 μs |
| LiveView `click_button` (event) | 843.83 μs |
| LiveView `click_button` (submit) | 1,297.92 μs |
| LiveView `submit` | 779.40 μs |
| LiveView `check` (isolated session) | 1,714.90 μs |
| LiveView `choose` (isolated session) | 1,702 μs |
| LiveView `select` (isolated session) | 1,647.83 μs |
| LiveView `check` (no change event, different form) | 882.27 μs |
| LiveView `select` (no change event, different form) | 888 μs |

The no-change-event scenarios use a smaller form than the original `check`
and `select` scenarios, so their difference measures both the form/fixture
and the event. Do not interpret that gap as the exact event cost.

## Current result (parent-form and label-lookup optimizations)

Measured on the same macOS Apple M3 / Elixir 1.19.5 / OTP 27.0 setup after
both optimizations. The focused form-component benchmark measured parent-form
lookup at ~226 μs before and ~115 μs after the first change. It measured
matching labels at ~200 μs with the original tree-only matcher versus ~57 μs
with a native-text rejection filter **in the same run**; possible matches still
use the original matching semantics. The full operation includes other work.

Medians from one `mix benchmark.operations` run (1 s warmup, 2 s sampling).
The benchmark now disables the endpoint's HTTP listener to reduce noise from
unrelated socket traffic; older measurements above had it enabled, so treat
before/after end-to-end comparisons as directional rather than controlled.

| Operation | Current median |
| --- | ---: |
| Static `fill_in` | 214.46 μs |
| Static `check` | 259.63 μs |
| Static `choose` | 364.83 μs |
| Static `select` | 270.46 μs |
| LiveView `check` | 1,685.63 μs |
| LiveView `choose` | 1,837.04 μs |
| LiveView `select` | 1,468.83 μs |
| LiveView `check` (no change event) | 647.42 μs |
| LiveView `select` (no change event) | 808.35 μs |

The LiveView scenarios run in separate sessions, unlike the initial baseline;
use their own isolated-session baseline-extension rows above for comparisons.
There is considerable run-to-run variance, especially in LiveView event
handling. No consistent end-to-end LiveView speedup has been established for
this second change.

Use each row as a before/after reference for the **same scenario on the same
machine**, preferably with repeated runs. Do not compare visit timings with
Benchee timings, or use cross-operation rankings alone to choose what to
optimize. These are end-to-end fixture timings, not isolated library overhead.
