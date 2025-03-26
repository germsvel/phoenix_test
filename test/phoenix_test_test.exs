defmodule PhoenixTestTest do
  use ExUnit.Case, async: true

  import PhoenixTest

  setup do
    %{conn: Phoenix.ConnTest.build_conn()}
  end

  describe "select/3" do
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
end
