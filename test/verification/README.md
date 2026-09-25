# Browser parity verification

These tests compare callback parameters from a real Chromium browser against PhoenixTest for the same interactions. The two runs have unique IDs. `PhoenixTest.Verification.Telemetry` observes Phoenix's LiveView `handle_event` and router-dispatch `:stop` events and sends only the relevant event/method and params to `PhoenixTest.Verification.Recorder`. ExUnit waits for and compares those observations. The verification LiveView and controller contain no recording code. Only the session-specific CSRF token and route run ID are excluded from the comparison.

The telemetry events reflect successful dispatch; lifecycle hooks or plugs that halt before reaching a callback would require a separate contract for what counts as "received."

Prerequisites: Node.js, npm, and Chromium for Playwright. From the repository root:

```sh
mix deps.get
MIX_ENV=test mix assets.build
npm --prefix test/verification ci
cd test/verification && npx playwright install chromium
cd ../..
mix test test/verification/verification_test.exs --include browser_verification
```

The browser suite is excluded from ordinary `mix test`; CI runs it as a separate job. If Chromium is already installed (for example, via Homebrew), you can skip `npx playwright install chromium` and set `PLAYWRIGHT_CHROMIUM_EXECUTABLE` to the full path of that executable when running the test. The runner also auto-detects `/opt/homebrew/bin/chromium`. The Playwright npm package is still required. Playwright's bundled Chromium is preferred in CI because its version is known to be compatible.

If port 4000 is occupied, set `PHOENIX_TEST_PORT` to an unused port for the test command (the browser runner inherits it). Playwright uses the *real* client scripts in `test/assets/js/app.js`; do not substitute LiveViewTest as the browser oracle.

To add a case, create or extend a verification page under `test/support/web_app/`, add the browser interaction to `browser.mjs`, and add a corresponding ExUnit PhoenixTest interaction and observation comparison. Wait for an observable callback/result rather than using time-based sleeps.
