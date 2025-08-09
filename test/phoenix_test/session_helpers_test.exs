defmodule PhoenixTest.SessionHelpersTest do
  use ExUnit.Case, async: true

  import PhoenixTest.SessionHelpers, only: [within: 3]

  describe "within" do
    test "runs action provided inside within" do
      initial = %{within: nil}

      assert_raise RuntimeError, "hello world", fn ->
        within(initial, "selector", fn _session ->
          raise "hello world"
        end)
      end
    end

    test "updates selector scope inside within" do
      initial = %{within: nil}

      within(initial, "#email-form", fn session ->
        assert session.within == "#email-form"
        session
      end)
    end

    test "scope is reset to nil outside of within call" do
      initial = %{within: nil}

      session =
        within(initial, "#email-form", fn session ->
          session
        end)

      assert session.within == nil
    end

    test "nests selector scopes when multiple withins" do
      initial = %{within: nil}

      within(initial, "main", fn session ->
        within(session, "#email-form", fn session ->
          assert session.within == "main #email-form"
          session
        end)
      end)
    end

    test "selector scopes do not interfere with adjacent withins" do
      initial = %{within: nil}

      initial
      |> within("#email-form", fn session ->
        session
      end)
      |> within("body", fn session ->
        within(session, "#user-form", fn session ->
          assert session.within == "body #user-form"
          session
        end)
      end)
    end
  end
end
