defmodule PhoenixTest.MultiEndpointTest do
  use ExUnit.Case, async: true

  import PhoenixTest

  describe "parallel tests with different endpoints via Config" do
    test "test using WebApp endpoint via Config.put_endpoint" do
      PhoenixTest.Config.put_endpoint(PhoenixTest.WebApp.Endpoint)

      Phoenix.ConnTest.build_conn()
      |> visit("/page/index")
      |> assert_has("h1", text: "Main page")
    end

    test "test using AnotherWebApp endpoint via Config.put_endpoint" do
      PhoenixTest.Config.put_endpoint(PhoenixTest.AnotherWebApp.Endpoint)

      Phoenix.ConnTest.build_conn()
      |> visit("/page")
      |> assert_has("h1", text: "AnotherWebApp page")
    end

    test "put_endpoint/2 on conn also sets process-level config" do
      conn = PhoenixTest.put_endpoint(Phoenix.ConnTest.build_conn(), PhoenixTest.AnotherWebApp.Endpoint)

      assert PhoenixTest.Config.endpoint() == PhoenixTest.AnotherWebApp.Endpoint
      assert conn.private[:phoenix_endpoint] == PhoenixTest.AnotherWebApp.Endpoint
    end

    test "conn.private endpoint takes precedence over process config" do
      PhoenixTest.Config.put_endpoint(PhoenixTest.AnotherWebApp.Endpoint)

      PhoenixTest.put_endpoint(Phoenix.ConnTest.build_conn(), PhoenixTest.WebApp.Endpoint)
      |> visit("/page/index")
      |> assert_has("h1", text: "Main page")
    end
  end
end
