defmodule PhoenixTest.Playwright.BrowserContext do
  @moduledoc """
  Interact with a Playwright `BrowserContext`.

  There is no official documentation, since this is considered Playwright internal.

  References:
  - https://github.com/microsoft/playwright/blob/main/packages/playwright-core/src/client/browserContext.ts
  """

  import PhoenixTest.Playwright.Connection, only: [post: 1, initializer: 1]

  @doc """
  Open a new browser page and return its `guid`.
  """
  def new_page(context_id) do
    resp = post(guid: context_id, method: "newPage")
    resp.result.page.guid
  end

  @doc """
  Start tracing. The results can be retrieved via `stop_tracing/2`.
  """
  def start_tracing(context_id, opts \\ []) do
    opts = Keyword.validate!(opts, screenshots: true, snapshots: true, sources: true)
    tracing_id = initializer(context_id).tracing.guid
    post(method: :tracingStart, guid: tracing_id, params: Map.new(opts))
    post(method: :tracingStartChunk, guid: tracing_id)
    :ok
  end

  @doc """
  Stop tracing and write zip file to specified output path.

  Trace can be viewed via either
  - `npx playwright show-trace trace.zip`
  - https://trace.playwright.dev
  """
  def stop_tracing(context_id, output_path) do
    tracing_id = initializer(context_id).tracing.guid
    resp = post(method: :tracingStopChunk, guid: tracing_id, params: %{mode: "archive"})
    zip_id = resp.result.artifact.guid
    zip_path = initializer(zip_id).absolutePath
    File.cp!(zip_path, output_path)
    post(method: :tracingStop, guid: tracing_id)
    :ok
  end
end
