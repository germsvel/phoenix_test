defmodule PhoenixTest.LiveTest do
  use ExUnit.Case, async: true

  import PhoenixTest
  import PhoenixTest.Assertions

  setup do
    %{conn: Phoenix.ConnTest.build_conn()}
  end

  describe "visit/2" do
    test "navigates to given LiveView page", %{conn: conn} do
      conn
      |> visit("/index_live")
      |> assert_has("h1", "Main LiveView page")
    end
  end
end
