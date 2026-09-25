defmodule PhoenixTest.Verification.Recorder.TelemetryIntegrationTest do
  use ExUnit.Case, async: false

  import PhoenixTest

  alias PhoenixTest.Verification.Recorder

  test "LiveView submits to the observed event" do
    run_id = Integer.to_string(System.unique_integer([:positive]))

    Phoenix.ConnTest.build_conn()
    |> visit("/verify/#{run_id}/live")
    |> fill_in("Name", with: "Ada")
    |> click_button("#verification-form button", "Save")

    assert %{event: "save", params: %{"person" => %{"name" => "Ada"}}} =
             Recorder.result(run_id)
  end

  test "static form submits to the observed controller" do
    run_id = Integer.to_string(System.unique_integer([:positive]))

    Phoenix.ConnTest.build_conn()
    |> visit("/verify/#{run_id}/static")
    |> fill_in("Name", with: "Ada")
    |> click_button("#verification-form button", "Save")

    assert %{method: "POST", params: %{"person" => %{"name" => "Ada"}}} =
             Recorder.result(run_id)
  end
end
