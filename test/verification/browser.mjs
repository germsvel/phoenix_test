import { existsSync } from "node:fs";
import { chromium } from "playwright";

const [kind, runId, interaction] = process.argv.slice(2);
if (
  !["live", "static"].includes(kind) ||
  !/^[A-Za-z0-9_-]+$/.test(runId ?? "") ||
  ![undefined, "checkbox_checked", "checkbox_unchecked", "roles", "disabled_readonly"].includes(interaction)
) {
  throw new Error("Usage: node browser.mjs live|static RUN_ID [checkbox_checked|checkbox_unchecked|roles|disabled_readonly]");
}

const deadline = setTimeout(() => {
  console.error("Browser verification timed out after 30 seconds");
  process.exit(1);
}, 30_000);

const homebrewChromium = "/opt/homebrew/bin/chromium";
const executablePath =
  process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE ??
  (existsSync(homebrewChromium) ? homebrewChromium : undefined);
const browser = await chromium.launch({ executablePath });
try {
  const page = await browser.newPage();
  page.setDefaultTimeout(10_000);
  const port = process.env.PHOENIX_TEST_PORT ?? "4000";
  await page.goto(`http://localhost:${port}/verify/${runId}/${kind}`);

  if (kind === "live") {
    // Wait for LiveSocket to connect; clicking before this could submit as a plain HTML form.
    await page.locator("[data-phx-session].phx-connected").waitFor();
  }

  if (interaction === "disabled_readonly") {
    await page.getByRole("button", { name: "Save Controls" }).click();
  } else if (interaction === "roles") {
    await page.getByLabel("Roles").selectOption(["reviewer", "admin"]);
    await page.getByRole("button", { name: "Save Roles" }).click();
  } else if (interaction?.startsWith("checkbox_")) {
    if (interaction === "checkbox_checked") {
      await page.getByRole("checkbox", { name: "Enabled" }).check();
    }
    await page.getByRole("button", { name: "Save Preference" }).click();
  } else {
    await page.getByLabel("Name").fill("Ada");
    await page.getByRole("button", { name: "Save", exact: true }).click();
  }
  await page.getByText("Saved").waitFor();
} finally {
  await browser.close();
  clearTimeout(deadline);
}
