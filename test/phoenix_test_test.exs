defmodule PhoenixTestTest do
  use ExUnit.Case, async: true

  import PhoenixTest

  setup do
    %{conn: PhoenixTest.put_endpoint(Phoenix.ConnTest.build_conn(), PhoenixTest.WebApp.Endpoint)}
  end

  describe "select/3" do
    test "does not accept both :option and deprecated :from", %{conn: conn} do
      session = visit(conn, "/live/index")

      assert_raise ArgumentError, ~r/:from/, fn ->
        select(session, "Race", option: "Elf", from: "Race")
      end
    end

    test "shows deprecation warning when using :from", %{conn: conn} do
      message =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          conn
          |> visit("/live/index")
          |> select("Elf", from: "Race")
        end)

      assert message =~ "select/3 with :from is deprecated"
    end
  end

  describe "select/4" do
    test "does not accept both :option and deprecated :from", %{conn: conn} do
      session = visit(conn, "/live/index")

      assert_raise ArgumentError, ~r/:from/, fn ->
        select(session, "select", "Race", option: "Elf", from: "Race")
      end
    end

    test "shows deprecation warning if passing `:from`", %{conn: conn} do
      message =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          conn
          |> visit("/live/index")
          |> select("#select-favorite-character", "Frodo", from: "Character")
        end)

      assert message =~ "select/4 with :from is deprecated"
    end
  end

  describe "put_endpoint/2" do
    test "can visit a page on a different endpoint", %{conn: conn} do
      Phoenix.ConnTest.build_conn()
      |> PhoenixTest.put_endpoint(PhoenixTest.AnotherWebApp.Endpoint)
      |> visit("/page")
      |> assert_has("h1", text: "AnotherWebApp page")

      conn
      |> visit("/live/index")
      |> assert_has("h1", text: "LiveView main page")
    end
  end
end
