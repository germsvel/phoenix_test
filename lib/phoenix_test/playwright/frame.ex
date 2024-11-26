defmodule PhoenixTest.Playwright.Frame do
  @moduledoc """
  Interact with a Playwright `Frame` (usually the "main" frame of a browser page).

  There is no official documentation, since this is considered Playwright internal.

  References:
  - https://github.com/microsoft/playwright/blob/main/packages/playwright-core/src/client/frame.ts
  """

  import PhoenixTest.Playwright.Connection, only: [post: 1]

  def goto(frame_id, url) do
    params = %{url: url}
    post(guid: frame_id, method: :goto, params: params)
    :ok
  end

  def url(frame_id) do
    [guid: frame_id, method: :url, params: %{}]
    |> post()
    |> unwrap_response(& &1.result.value)
  end

  def press(frame_id, selector, key) do
    params = %{selector: selector, key: key}
    post(guid: frame_id, method: :press, params: params)
    :ok
  end

  def title(frame_id) do
    [guid: frame_id, method: :title]
    |> post()
    |> unwrap_response(& &1.result.value)
  end

  def expect(frame_id, params) do
    params = Enum.into(params, %{isNot: false})

    [guid: frame_id, method: :expect, params: params]
    |> post()
    |> unwrap_response(& &1.result.matches)
  end

  def wait_for_selector(frame_id, params) do
    [guid: frame_id, method: :waitForSelector, params: params]
    |> post()
    |> unwrap_response(& &1.result.element)
  end

  def inner_html(frame_id, selector) do
    params = %{selector: selector}

    [guid: frame_id, method: :innerHTML, params: params]
    |> post()
    |> unwrap_response(& &1.result.value)
  end

  def content(frame_id) do
    [guid: frame_id, method: :content]
    |> post()
    |> unwrap_response(& &1.result.value)
  end

  def fill(frame_id, selector, value, opts \\ []) do
    params = %{selector: selector, value: value, strict: true}
    params = Enum.into(opts, params)

    [guid: frame_id, method: :fill, params: params]
    |> post()
    |> unwrap_response(& &1)
  end

  def select_option(frame_id, selector, options, opts \\ []) do
    params = %{selector: selector, options: options, strict: true}
    params = Enum.into(opts, params)

    [guid: frame_id, method: :selectOption, params: params]
    |> post()
    |> unwrap_response(& &1)
  end

  def check(frame_id, selector, opts \\ []) do
    params = %{selector: selector, strict: true}
    params = Enum.into(opts, params)

    [guid: frame_id, method: :check, params: params]
    |> post()
    |> unwrap_response(& &1)
  end

  def uncheck(frame_id, selector, opts \\ []) do
    params = %{selector: selector, strict: true}
    params = Enum.into(opts, params)

    [guid: frame_id, method: :uncheck, params: params]
    |> post()
    |> unwrap_response(& &1)
  end

  def set_input_files(frame_id, selector, paths, opts \\ []) do
    params = %{selector: selector, localPaths: paths, strict: true}
    params = Enum.into(opts, params)

    [guid: frame_id, method: :setInputFiles, params: params]
    |> post()
    |> unwrap_response(& &1)
  end

  def click(frame_id, selector, opts \\ []) do
    params = %{selector: selector, waitUntil: "load", strict: true}
    params = Enum.into(opts, params)

    [guid: frame_id, method: :click, params: params]
    |> post()
    |> unwrap_response(& &1)
  end

  defp unwrap_response(response, fun) do
    case response do
      %{error: _} = error -> {:error, error}
      _ -> {:ok, fun.(response)}
    end
  end
end
