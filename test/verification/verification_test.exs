defmodule PhoenixTest.VerificationTest do
  use ExUnit.Case, async: false

  import PhoenixTest

  alias PhoenixTest.Verification.Recorder

  @moduletag :browser_verification

  test "LiveView handle_event receives the same params" do
    browser = browser_observation("live")
    run_id = run_id()

    Phoenix.ConnTest.build_conn()
    |> visit("/verify/#{run_id}/live")
    |> fill_in("Name", with: "Ada")
    |> click_button("#verification-form button", "Save")

    assert normalize(Recorder.result(run_id)) == normalize(browser)
  end

  test "controller receives the same method and params" do
    browser = browser_observation("static")
    run_id = run_id()

    Phoenix.ConnTest.build_conn()
    |> visit("/verify/#{run_id}/static")
    |> fill_in("Name", with: "Ada")
    |> click_button("#verification-form button", "Save")

    assert normalize(Recorder.result(run_id)) == normalize(browser)
  end

  test "LiveView receives the browser checkbox params when checked and unchecked" do
    for checked <- [false, true] do
      compare_checkbox("live", checked)
    end
  end

  test "controller receives the browser checkbox params when checked and unchecked" do
    for checked <- [false, true] do
      compare_checkbox("static", checked)
    end
  end

  test "LiveView receives the browser's ordered multiple-select params" do
    compare_roles("live")
  end

  test "controller receives the browser's ordered multiple-select params" do
    compare_roles("static")
  end

  test "LiveView omits disabled controls and includes readonly controls like the browser" do
    compare_disabled_readonly("live")
  end

  test "controller omits disabled controls and includes readonly controls like the browser" do
    compare_disabled_readonly("static")
  end

  defp compare_disabled_readonly(kind) do
    browser = browser_observation(kind, "disabled_readonly")
    run_id = run_id()

    Phoenix.ConnTest.build_conn()
    |> visit("/verify/#{run_id}/#{kind}")
    |> click_button("Save Controls")

    expected_params = %{
      "person" => %{
        "active" => "included",
        "readonly_text" => "locked",
        "readonly_notes" => "locked notes"
      }
    }

    expected =
      if kind == "live",
        do: %{event: "save", params: expected_params},
        else: %{method: "POST", params: expected_params}

    assert normalize(browser) == expected
    assert normalize(Recorder.result(run_id)) == expected
  end

  defp compare_roles(kind) do
    browser = browser_observation(kind, "roles")
    run_id = run_id()

    Phoenix.ConnTest.build_conn()
    |> visit("/verify/#{run_id}/#{kind}")
    |> select("Roles", option: ["Reviewer", "Admin"])
    |> click_button("Save Roles")

    assert get_in(browser.params, ["person", "roles"]) == ["admin", "reviewer"]
    assert normalize(Recorder.result(run_id)) == normalize(browser)
  end

  defp compare_checkbox(kind, checked) do
    browser = browser_observation(kind, if(checked, do: "checkbox_checked", else: "checkbox_unchecked"))
    run_id = run_id()

    session = visit(Phoenix.ConnTest.build_conn(), "/verify/#{run_id}/#{kind}")
    session = if checked, do: check(session, "Enabled"), else: session
    click_button(session, "Save Preference")

    assert get_in(browser.params, ["person", "enabled"]) == if(checked, do: "true", else: "false")
    assert normalize(Recorder.result(run_id)) == normalize(browser)
  end

  defp browser_observation(kind, interaction \\ nil) do
    run_id = run_id()
    script = Path.expand("browser.mjs", __DIR__)
    args = [script, kind, run_id] ++ if(interaction, do: [interaction], else: [])

    {output, status} =
      System.cmd("node", args,
        cd: Path.dirname(script),
        stderr_to_stdout: true
      )

    assert status == 0, "Playwright #{kind} case failed:\n#{output}"
    Recorder.result(run_id)
  end

  defp normalize(%{params: params} = observation) do
    %{observation | params: Map.drop(params, ["_csrf_token", "run_id"])}
  end

  defp run_id, do: Base.url_encode64(:crypto.strong_rand_bytes(12), padding: false)
end
