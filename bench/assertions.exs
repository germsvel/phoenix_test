ExUnit.start()

defmodule PhoenixTestBenchmark do
  @moduledoc """
  We mimic an ExUnit test so that LiveView helpers work as expected.
  """
  use ExUnit.Case, async: true

  import ExUnit.Assertions, only: [assert: 1]
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint PhoenixTest.WebApp.Endpoint

  test "run assertion benchmarks" do
    {:ok, _} = Supervisor.start_link([{Phoenix.PubSub, name: PhoenixTest.PubSub}], strategy: :one_for_one)
    {:ok, _} = PhoenixTest.WebApp.Endpoint.start_link()

    conn = Phoenix.ConnTest.build_conn()
    {:ok, view, html} = live(conn, "/live/index")
    session = PhoenixTest.visit(conn, "/live/index")

    Benchee.run(%{
      "PhoenixTest.assert_has/2" => fn ->
        PhoenixTest.assert_has(session, "[data-role='title']")
      end,
      "PhoenixTest.assert_has/3, tag selector" => fn ->
        PhoenixTest.assert_has(session, "li", text: "Aragorn")
      end,
      "PhoenixTest.assert_has/3, id+tag selector" => fn ->
        PhoenixTest.assert_has(session, "#multiple-items li", text: "Aragorn")
      end,
      "PhoenixTest.assert_has/3, using within id, tag selector" => fn ->
        PhoenixTest.within(session, "#multiple-items", fn s ->
          PhoenixTest.assert_has(s, "li", text: "Aragorn")
        end)
      end,
      "LiveView string matching" => fn ->
        assert html =~ "main page"
      end,
      "LiveView tag selector" => fn ->
        assert has_element?(view, "li", "Aragorn")
      end,
      "LiveView id+tag selector" => fn ->
        assert has_element?(view, "#multiple-items li", "Aragorn")
      end
    })
  end
end
