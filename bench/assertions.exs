defmodule PhoenixTestBenchmark do
  @moduledoc """
  This module is necessary to be able to set the @endpoint attribute, needed by Phoenix.ConnTest.
  """

  import ExUnit.Assertions, only: [assert: 1]
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  import Plug.Conn

  @endpoint PhoenixTest.WebApp.Endpoint

  def run do
    {:ok, _} = Supervisor.start_link([{Phoenix.PubSub, name: PhoenixTest.PubSub}], strategy: :one_for_one)
    {:ok, _} = PhoenixTest.WebApp.Endpoint.start_link()

    Benchee.run(%{
      "PhoenixTest.assert_has/2" => {
        fn {_input, session} ->
          PhoenixTest.assert_has(session, "[data-role='title']")
        end,
        before_scenario: &session_setup_fn/1
      },
      "PhoenixTest.assert_has/3, tag selector" => {
        fn {_input, session} ->
          PhoenixTest.assert_has(session, "li", text: "Aragorn")
        end,
        before_scenario: &session_setup_fn/1
      },
      "PhoenixTest.assert_has/3, id+tag selector" => {
        fn {_input, session} ->
          PhoenixTest.assert_has(session, "#multiple-items li", text: "Aragorn")
        end,
        before_scenario: &session_setup_fn/1
      },
      "PhoenixTest.assert_has/3, using within id, tag selector" => {
        fn {_input, session} ->
          PhoenixTest.within(session, "#multiple-items", fn s ->
            PhoenixTest.assert_has(s, "li", text: "Aragorn")
          end)
        end,
        before_scenario: &session_setup_fn/1
      },
      "LiveView string matching" => {
        fn {_input, %{html: html}} ->
          assert html =~ "[data-role='title']"
        end,
        before_scenario: &lv_setup_fn/1
      }
    })
  end

  defp session_setup_fn(input) do
    conn = Phoenix.ConnTest.build_conn()
    session = PhoenixTest.visit(conn, "/page/index")
    {input, session}
  end

  defp lv_setup_fn(input) do
    conn = Phoenix.ConnTest.build_conn()
    {:ok, view, html} = live(conn, "/page/index")
    {input, %{view: view, html: html}}
  end
end

PhoenixTestBenchmark.run()
