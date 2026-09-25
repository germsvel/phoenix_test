import { existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright";

const [kind, runId, interaction] = process.argv.slice(2);
if (
  !["live", "static"].includes(kind) ||
  !/^[A-Za-z0-9_-]+$/.test(runId ?? "") ||
  ![undefined, "checkbox_checked", "checkbox_unchecked", "roles", "disabled_readonly", "changes", "get_form", "method_put", "method_delete", "submit_first", "submit_second", "submit_unnamed", "submit_external", "submit_enter", "submit_redirected", "submit_search", "defaults", "nested", "dynamic", "uploads", "live_uploads", "click_event", "push_event", "patch_link", "navigate_link", "redirect_button"].includes(interaction)
) {
  throw new Error("Usage: node browser.mjs live|static RUN_ID [checkbox_checked|checkbox_unchecked|roles|disabled_readonly|changes|get_form|method_put|method_delete|submit_first|submit_second|submit_unnamed|submit_external|submit_enter|submit_redirected|submit_search|defaults|nested|dynamic|uploads|live_uploads|click_event|push_event|patch_link|navigate_link|redirect_button]");
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

  if (interaction === "click_event") {
    await page.getByRole("button", { name: "Record Click" }).click();
  } else if (interaction === "push_event") {
    await page.getByRole("button", { name: "Push Event" }).click();
  } else if (interaction === "patch_link") {
    await page.getByRole("link", { name: "Patch Verify" }).click();
  } else if (interaction === "navigate_link") {
    await page.getByRole("link", { name: "Navigate Verify" }).click();
  } else if (interaction === "redirect_button") {
    await page.getByRole("button", { name: "Redirect Verify" }).click();
  } else if (interaction === "live_uploads") {
    if (kind !== "live") throw new Error("live_uploads requires a LiveView");
    await page.getByLabel("Photos").setInputFiles([
      fileURLToPath(new URL("../files/elixir.jpg", import.meta.url)),
      fileURLToPath(new URL("../files/phoenix.png", import.meta.url)),
    ]);
    await page.getByRole("button", { name: "Save Photos" }).click();
  } else if (interaction === "uploads") {
    if (kind !== "static") throw new Error("uploads currently requires a static page");
    await page.getByLabel("Upload one").setInputFiles(fileURLToPath(new URL("../files/elixir.jpg", import.meta.url)));
    await page.getByLabel("Upload two").setInputFiles(fileURLToPath(new URL("../files/phoenix.png", import.meta.url)));
    await page.getByRole("button", { name: "Save Files" }).click();
  } else if (interaction === "dynamic") {
    if (kind !== "live") throw new Error("dynamic requires a LiveView");
    await page.getByLabel("Kept field").fill("Ada");
    await page.getByLabel("Stale field").fill("discard me");
    await page.getByRole("button", { name: "Remove Stale" }).click();
    await page.getByLabel("Stale field").waitFor({ state: "detached" });
    await page.getByRole("button", { name: "Add Field" }).click();
    await page.getByLabel("Added field").waitFor();
    await page.getByLabel("Added field").fill("fresh");
    await page.getByRole("button", { name: "Save Dynamic" }).click();
  } else if (interaction === "nested") {
    await page.getByRole("button", { name: "Save Nested Data" }).click();
  } else if (interaction === "defaults") {
    await page.getByRole("button", { name: "Save Defaults" }).click();
  } else if (interaction?.startsWith("submit_")) {
    if (interaction === "submit_enter") {
      await page.getByLabel("Submitter name").fill("Ada");
      await page.getByLabel("Submitter name").press("Enter");
    } else {
      const names = {
        submit_first: "First Action",
        submit_second: "Second Action",
        submit_unnamed: "Unnamed Action",
        submit_external: "External Action",
        submit_redirected: "Redirected Action",
        submit_search: "Search Action",
      };
      await page.getByRole("button", { name: names[interaction] }).click();
    }
  } else if (interaction === "method_put" || interaction === "method_delete") {
    if (kind !== "static") throw new Error("method overrides require a static page");
    if (interaction === "method_put") {
      await page.getByLabel("Update name").fill("Ada");
      await page.getByRole("button", { name: "Update Record" }).click();
    } else {
      await page.getByLabel("Delete reason").fill("duplicate");
      await page.getByRole("button", { name: "Remove Record" }).click();
    }
  } else if (interaction === "get_form") {
    if (kind !== "static") throw new Error("get_form requires a static page");
    await page.getByLabel("Query").fill("Ada & Bob");
    await page.getByRole("button", { name: "Search Records" }).click();
  } else if (interaction === "changes") {
    if (kind !== "live") throw new Error("changes requires a LiveView");
    await page.getByLabel("Change role").selectOption("admin");
    await page.locator("#verification-change-count").filter({ hasText: /^1$/ }).waitFor();
    await page.getByRole("checkbox", { name: "Change enabled" }).check();
    await page.locator("#verification-change-count").filter({ hasText: /^2$/ }).waitFor();
    await page.getByLabel("Change name").fill("Ada");
    await page.locator("#verification-change-count").filter({ hasText: /^3$/ }).waitFor();
  } else if (interaction === "disabled_readonly") {
    await page.getByRole("button", { name: "Save Controls" }).click();
  } else if (interaction === "roles") {
    await page.getByLabel("Roles", { exact: true }).selectOption(["reviewer", "admin"]);
    await page.getByRole("button", { name: "Save Roles" }).click();
  } else if (interaction?.startsWith("checkbox_")) {
    if (interaction === "checkbox_checked") {
      await page.getByRole("checkbox", { name: "Enabled", exact: true }).check();
    }
    await page.getByRole("button", { name: "Save Preference" }).click();
  } else {
    await page.getByLabel("Name", { exact: true }).fill("Ada");
    await page.getByRole("button", { name: "Save", exact: true }).click();
  }
  const destinations = {
    patch_link: `/verify/${runId}/live?tab=details`,
    navigate_link: `/verify/${runId}/live/destination`,
    redirect_button: `/verify/${runId}/static`,
  };
  if (interaction in destinations) {
    await page.waitForURL((url) => url.pathname + url.search === destinations[interaction]);
    console.log(`DESTINATION:${new URL(page.url()).pathname + new URL(page.url()).search}`);
  } else if (interaction !== "changes") {
    await page.getByText("Saved").waitFor();
  }
} finally {
  await browser.close();
  clearTimeout(deadline);
}
