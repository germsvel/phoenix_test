defmodule PhoenixTest.PlaywrightTest do
  use PhoenixTest.Case,
    async: true,
    parameterize: Enum.map(~w(chromium firefox)a, &%{playwright: [browser: &1]})

  describe "render_page_title/1" do
    unless System.version() in ~w(1.15.0 1.16.0 1.17.0) do
      test "runs in multiple browsers via ExUnit `parameterize`", %{conn: conn} do
        session = visit(conn, "/live/index")
        assert %PhoenixTest.Playwright{} = session

        title = PhoenixTest.Driver.render_page_title(session)
        assert title == "PhoenixTest is the best!"
      end
    end

    @tag playwright: false
    test "'@tag playwright: false' forces live driver", %{conn: conn} do
      session = visit(conn, "/live/index")
      assert %PhoenixTest.Live{} = session

      title = PhoenixTest.Driver.render_page_title(session)
      assert title == "PhoenixTest is the best!"
    end
  end
end
