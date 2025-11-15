defmodule PhoenixTest.ButtebeeTest do
  use ExUnit.Case, async: true

  import PhoenixTest

  setup do
    conn = PhoenixTest.Butterbee.build()
    # Failing (driver in wrong state, still begore goto?)
    # on_exit(fn -> PhoenixTest.Butterbee.close(conn) end)
    %{conn: conn}
  end

  describe "visit/2" do
    test "navigates to given LiveView page", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> assert_has("h1", text: "LiveView main page")
    end
  end
end
