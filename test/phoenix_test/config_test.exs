defmodule PhoenixTest.ConfigTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.Config

  describe "put_endpoint/1 and endpoint/0" do
    test "stores and retrieves endpoint for current process" do
      Config.put_endpoint(PhoenixTest.WebApp.Endpoint)
      assert Config.endpoint() == PhoenixTest.WebApp.Endpoint
    end

    test "different processes see different endpoints" do
      Config.put_endpoint(PhoenixTest.WebApp.Endpoint)

      task =
        Task.async(fn ->
          Config.put_endpoint(PhoenixTest.AnotherWebApp.Endpoint)
          Config.endpoint()
        end)

      other_process_endpoint = Task.await(task)

      assert Config.endpoint() == PhoenixTest.WebApp.Endpoint
      assert other_process_endpoint == PhoenixTest.AnotherWebApp.Endpoint
    end

    test "process without put_endpoint falls back to Application config" do
      Process.delete(:phoenix_test_endpoint)

      assert Config.endpoint() == PhoenixTest.WebApp.Endpoint
    end
  end

  describe "endpoint!/0" do
    test "returns endpoint when set via put_endpoint" do
      Config.put_endpoint(PhoenixTest.WebApp.Endpoint)
      assert Config.endpoint!() == PhoenixTest.WebApp.Endpoint
    end

    test "raises when no endpoint configured" do
      Process.delete(:phoenix_test_endpoint)
      original = Application.get_env(:phoenix_test, :endpoint)
      Application.delete_env(:phoenix_test, :endpoint)

      try do
        assert_raise ArgumentError, ~r/No endpoint configured/, fn ->
          Config.endpoint!()
        end
      after
        if original, do: Application.put_env(:phoenix_test, :endpoint, original)
      end
    end
  end
end
