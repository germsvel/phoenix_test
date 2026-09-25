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

  test "LiveView change includes untouched-field markers" do
    run_id = Integer.to_string(System.unique_integer([:positive]))

    Phoenix.ConnTest.build_conn()
    |> visit("/verify/#{run_id}/live")
    |> select("Change role", option: "Admin")

    assert Recorder.result(run_id) == %{
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
           }
  end

  test "static GET form replaces the action query with submitted fields" do
    run_id = Integer.to_string(System.unique_integer([:positive]))

    Phoenix.ConnTest.build_conn()
    |> visit("/verify/#{run_id}/static")
    |> fill_in("Query", with: "Ada & Bob")
    |> click_button("Search Records")

    assert Recorder.result(run_id) == %{
             method: "GET",
             path: "/verify/#{run_id}/static/get",
             params: %{
               "run_id" => run_id,
               "q" => "Ada & Bob",
               "blank" => "",
               "tag" => ["first", "second"],
               "shared" => "new"
             }
           }
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
