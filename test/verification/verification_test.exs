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

  test "static links and redirects reach the same controller paths and params" do
    for {interaction, link, expected} <- [
          {"static_link", "Visit Record",
           [
             %{method: "GET", path: "/verify/:run_id/static/destination", params: %{"origin" => "link", "empty" => ""}}
           ]},
          {"static_redirect", "Follow Record Redirect",
           [
             %{method: "GET", path: "/verify/:run_id/static/redirect", params: %{"step" => "first"}},
             %{method: "GET", path: "/verify/:run_id/static/destination", params: %{"origin" => "redirect"}}
           ]}
        ] do
      browser = browser_observations("static", interaction, length(expected))
      run_id = run_id()

      Phoenix.ConnTest.build_conn()
      |> visit("/verify/#{run_id}/static")
      |> click_link(link)

      assert Enum.map(browser, &normalize/1) == expected
      assert run_id |> Recorder.results(length(expected)) |> Enum.map(&normalize/1) == expected
    end
  end

  test "static data-method link and button reach DELETE controller with browser params" do
    for {interaction, target, click} <- [
          {"static_delete", "Delete via Link", &click_link/2},
          {"static_delete_button", "Delete via Button", &click_button/2}
        ] do
      browser = browser_observation("static", interaction)
      run_id = run_id()

      Phoenix.ConnTest.build_conn()
      |> visit("/verify/#{run_id}/static")
      |> click.(target)

      phoenix = Recorder.result(run_id)
      assert is_binary(browser.params["_csrf_token"])
      assert is_binary(phoenix.params["_csrf_token"])

      expected = %{
        method: "DELETE",
        path: "/verify/:run_id/static/data_action",
        params: %{"_method" => "delete"}
      }

      assert normalize(browser) == expected
      assert normalize(phoenix) == expected
    end
  end

  test "Live phx-click bound values and JS.push match browser event params" do
    for {interaction, button, expected} <- [
          {"click_event", "Record Click",
           %{event: "verify_click", params: %{"id" => "42", "origin" => "button", "value" => ""}}},
          {"push_event", "Push Event", %{event: "verify_push", params: %{"id" => "77", "origin" => "js", "value" => ""}}}
        ] do
      browser = browser_observation("live", interaction)
      run_id = run_id()

      Phoenix.ConnTest.build_conn()
      |> visit("/verify/#{run_id}/live")
      |> click_button(button)

      assert normalize(browser) == expected
      assert normalize(Recorder.result(run_id)) == expected
    end
  end

  test "Live patch, navigate, and redirect destinations match Chromium" do
    for {interaction, target, expected} <- [
          {"patch_link", "Patch Verify", "/verify/:run_id/live?tab=details"},
          {"navigate_link", "Navigate Verify", "/verify/:run_id/live/destination"},
          {"redirect_button", "Redirect Verify", "/verify/:run_id/static"}
        ] do
      browser = browser_destination(interaction)
      run_id = run_id()
      session = visit(Phoenix.ConnTest.build_conn(), "/verify/#{run_id}/live")

      session =
        if interaction == "redirect_button",
          do: click_button(session, target),
          else: click_link(session, target)

      assert browser == expected
      assert normalize_path(PhoenixTest.Driver.current_path(session)) == expected
    end
  end

  test "Live uploads match browser filename, type, and size" do
    browser = browser_observations("live", "live_uploads", :upload_save)
    run_id = run_id()

    Phoenix.ConnTest.build_conn()
    |> visit("/verify/#{run_id}/live")
    |> upload("Photos", "test/files/elixir.jpg")
    |> upload("Photos", "test/files/phoenix.png")
    |> click_button("Save Photos")

    expected = %{
      event: "upload_save",
      params: %{},
      uploads: [
        %{filename: "elixir.jpg", content_type: "image/jpeg", size: File.stat!("test/files/elixir.jpg").size},
        %{filename: "phoenix.png", content_type: "image/png", size: File.stat!("test/files/phoenix.png").size}
      ]
    }

    assert normalize(browser) == expected
    assert normalize(upload_result(run_id)) == expected
  end

  test "static multipart uploads match browser filename, type, and size" do
    browser = browser_observation("static", "uploads")
    run_id = run_id()

    Phoenix.ConnTest.build_conn()
    |> visit("/verify/#{run_id}/static")
    |> upload("Upload one", "test/files/elixir.jpg")
    |> upload("Upload two", "test/files/phoenix.png")
    |> click_button("Save Files")

    expected = %{
      method: "POST",
      params: %{
        "files" => [
          %{filename: "elixir.jpg", content_type: "image/jpeg", size: File.stat!("test/files/elixir.jpg").size},
          %{filename: "phoenix.png", content_type: "image/png", size: File.stat!("test/files/phoenix.png").size}
        ]
      }
    }

    assert normalize(browser) == expected
    assert normalize(Recorder.result(run_id)) == expected
  end

  test "LiveView dynamic form excludes removed fields and retains other values" do
    browser = "live" |> browser_observations("dynamic", 3) |> List.last()
    run_id = run_id()

    Phoenix.ConnTest.build_conn()
    |> visit("/verify/#{run_id}/live")
    |> fill_in("Kept field", with: "Ada")
    |> fill_in("Stale field", with: "discard me")
    |> click_button("Remove Stale")
    |> click_button("Add Field")
    |> fill_in("Added field", with: "fresh")
    |> click_button("Save Dynamic")

    expected = %{event: "save", params: %{"person" => %{"kept" => "Ada", "added" => "fresh"}}}
    assert normalize(browser) == expected
    assert run_id |> Recorder.results(3) |> List.last() |> normalize() == expected
  end

  test "nested, repeated, and indexed names match the browser in LiveView" do
    compare_nested("live")
  end

  test "nested, repeated, and indexed names match the browser in Static" do
    compare_nested("static")
  end

  defp compare_nested(kind) do
    browser = browser_observation(kind, "nested")
    run_id = run_id()

    Phoenix.ConnTest.build_conn()
    |> visit("/verify/#{run_id}/#{kind}")
    |> click_button("Save Nested Data")

    expected_params = %{
      "profile" => %{
        "tags" => ["alpha", "beta"],
        "contacts" => %{
          "0" => %{"name" => "Ada", "role" => "admin"},
          "1" => %{"name" => "Lin", "role" => "editor"}
        },
        "settings" => %{"theme" => "dark"}
      },
      "duplicate" => "second"
    }

    expected =
      if kind == "live",
        do: %{event: "save", params: expected_params},
        else: %{method: "POST", params: expected_params}

    assert normalize(browser) == expected
    assert normalize(Recorder.result(run_id)) == expected
  end

  test "radio, omitted controls, and untouched defaults match the browser in LiveView" do
    compare_defaults("live")
  end

  test "radio, omitted controls, and untouched defaults match the browser in Static" do
    compare_defaults("static")
  end

  defp compare_defaults(kind) do
    browser = browser_observation(kind, "defaults")
    run_id = run_id()

    Phoenix.ConnTest.build_conn()
    |> visit("/verify/#{run_id}/#{kind}")
    |> click_button("Save Defaults")

    expected_params = %{
      "person" => %{"choice" => "selected", "default_text" => "Original", "default_choice" => "first"}
    }

    expected =
      if kind == "live",
        do: %{event: "save", params: expected_params},
        else: %{method: "POST", params: expected_params}

    assert normalize(browser) == expected
    assert normalize(Recorder.result(run_id)) == expected
  end

  test "named, unnamed, external, and implicit submitters match the browser in LiveView" do
    for action <- ~w(first second unnamed external enter) do
      compare_submitter("live", action)
    end
  end

  test "named, unnamed, external, and implicit submitters match the browser in Static" do
    for action <- ~w(first second unnamed external enter) do
      compare_submitter("static", action)
    end
  end

  test "static button-level action and method overrides match the browser" do
    for {action, button, method, path} <- [
          {"redirected", "Redirected Action", "POST", "/verify/:run_id/static/submitter"},
          {"search", "Search Action", "GET", "/verify/:run_id/static/get"}
        ] do
      browser = browser_observation("static", "submit_#{action}")
      run_id = run_id()

      Phoenix.ConnTest.build_conn()
      |> visit("/verify/#{run_id}/static")
      |> click_button(button)

      expected = %{
        method: method,
        path: path,
        params: %{"person" => %{"name" => "Original", "action" => action}}
      }

      assert normalize(browser) == expected
      assert normalize(Recorder.result(run_id)) == expected
    end
  end

  defp compare_submitter(kind, action) do
    browser = browser_observation(kind, "submit_#{action}")
    run_id = run_id()
    session = visit(Phoenix.ConnTest.build_conn(), "/verify/#{run_id}/#{kind}")

    session =
      if action == "enter" do
        session |> fill_in("Submitter name", with: "Ada") |> submit()
      else
        button = %{
          "first" => "First Action",
          "second" => "Second Action",
          "unnamed" => "Unnamed Action",
          "external" => "External Action"
        }

        click_button(session, button[action])
      end

    assert_has(session, if(kind == "live", do: "#verification-done", else: "body"), text: "Saved")

    params = %{"person" => %{"name" => if(action == "enter", do: "Ada", else: "Original")}}

    params =
      if action == "unnamed",
        do: params,
        else: put_in(params, ["person", "action"], if(action == "enter", do: "first", else: action))

    expected =
      if kind == "live",
        do: %{event: "save", params: params},
        else: %{method: "POST", params: params}

    assert normalize(browser) == expected
    assert normalize(Recorder.result(run_id)) == expected
  end

  test "static GET form sends browser query params to its action path" do
    browser = browser_observation("static", "get_form")
    run_id = run_id()

    Phoenix.ConnTest.build_conn()
    |> visit("/verify/#{run_id}/static")
    |> fill_in("Query", with: "Ada & Bob")
    |> click_button("Search Records")

    expected = %{
      method: "GET",
      path: "/verify/:run_id/static/get",
      params: %{"q" => "Ada & Bob", "blank" => "", "tag" => ["first", "second"], "shared" => "new"}
    }

    assert normalize(browser) == expected
    assert normalize(Recorder.result(run_id)) == expected
  end

  test "static hidden _method submits PUT to the controller like the browser" do
    compare_method_override("put", "Update name", "Ada", "Update Record", %{"person" => %{"name" => "Ada"}})
  end

  test "static hidden _method submits DELETE to the controller like the browser" do
    compare_method_override("delete", "Delete reason", "duplicate", "Remove Record", %{"reason" => "duplicate"})
  end

  defp compare_method_override(method, label, value, button, form_params) do
    browser = browser_observation("static", "method_#{method}")
    run_id = run_id()

    Phoenix.ConnTest.build_conn()
    |> visit("/verify/#{run_id}/static")
    |> fill_in(label, with: value)
    |> click_button(button)

    phoenix = Recorder.result(run_id)
    assert is_binary(browser.params["_csrf_token"])
    assert is_binary(phoenix.params["_csrf_token"])

    expected = %{method: String.upcase(method), params: Map.put(form_params, "_method", method)}
    assert normalize(browser) == expected
    assert normalize(phoenix) == expected
  end

  test "LiveView change events send full params and targets in interaction order" do
    browser = browser_observations("live", "changes", 3)
    run_id = run_id()

    Phoenix.ConnTest.build_conn()
    |> visit("/verify/#{run_id}/live")
    |> select("Change role", option: "Admin")
    |> check("Change enabled")
    |> fill_in("Change name", with: "Ada")

    expected = [
      %{
        event: "validate",
        params: %{
          "_target" => ["person", "role"],
          "person" => %{
            "name" => "Original",
            "role" => "admin",
            "enabled" => "false",
            "_unused_name" => "",
            "_unused_enabled" => ""
          }
        }
      },
      %{
        event: "validate",
        params: %{
          "_target" => ["person", "enabled"],
          "person" => %{"name" => "Original", "role" => "admin", "enabled" => "true", "_unused_name" => ""}
        }
      },
      %{
        event: "validate",
        params: %{
          "_target" => ["person", "name"],
          "person" => %{"name" => "Ada", "role" => "admin", "enabled" => "true"}
        }
      }
    ]

    phoenix = run_id |> Recorder.results(3) |> Enum.map(&normalize/1)
    assert phoenix == Enum.map(browser, &normalize/1)
    assert Enum.map(browser, &normalize/1) == expected
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
    [observation] = browser_observations(kind, interaction, 1)
    observation
  end

  defp browser_observations(kind, interaction, count) do
    run_id = run_id()
    script = Path.expand("browser.mjs", __DIR__)
    args = [script, kind, run_id] ++ if(interaction, do: [interaction], else: [])

    {output, status} =
      System.cmd("node", args,
        cd: Path.dirname(script),
        stderr_to_stdout: true
      )

    assert status == 0, "Playwright #{kind} case failed:\n#{output}"
    if count == :upload_save, do: upload_result(run_id), else: Recorder.results(run_id, count)
  end

  defp upload_result(run_id) do
    Enum.reduce_while(1..6, nil, fn _, _ ->
      observation = Recorder.result(run_id)
      if observation.event == "upload_save", do: {:halt, observation}, else: {:cont, nil}
    end)
  end

  defp browser_destination(interaction) do
    script = Path.expand("browser.mjs", __DIR__)

    {output, status} =
      System.cmd("node", [script, "live", run_id(), interaction], cd: Path.dirname(script), stderr_to_stdout: true)

    assert status == 0, "Playwright navigation failed:\n#{output}"
    [_, path] = Regex.run(~r/DESTINATION:(\S+)/, output)
    normalize_path(path)
  end

  defp normalize_path(path), do: String.replace(path, ~r|^/verify/[^/]+/|, "/verify/:run_id/")

  defp normalize(%{path: path} = observation) do
    observation
    |> Map.put(:path, String.replace(path, ~r|^/verify/[^/]+/|, "/verify/:run_id/"))
    |> Map.update!(:params, &Map.drop(&1, ["_csrf_token", "run_id"]))
  end

  defp normalize(%{params: params} = observation) do
    %{observation | params: Map.drop(params, ["_csrf_token", "run_id"])}
  end

  defp run_id, do: Base.url_encode64(:crypto.strong_rand_bytes(12), padding: false)
end
