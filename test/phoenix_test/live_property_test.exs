defmodule PhoenixTest.LivePropertyTest do
  use ExUnit.Case, async: true
  use ExUnit.Case, async: true
  use ExUnitProperties

  import PhoenixTest, except: [check: 2]

  setup do
    %{conn: Phoenix.ConnTest.build_conn()}
  end

  property "assert_has/refute_has timeout handles async navigates property", %{conn: conn} do
    check all(
            timeout <- integer(100..500),
            navigate_wait_time <- integer(100..500)
          ) do
      session =
        conn
        |> visit("/live/async_page?wait_time=#{navigate_wait_time}")
        |> click_button("Async navigate!")

      if timeout >= navigate_wait_time do
        assert_has(session, "h1", text: "LiveView page 2", timeout: timeout)
      else
        refute_has(session, "h1", text: "LiveView page 2", timeout: timeout)
      end
    end
  end
end
