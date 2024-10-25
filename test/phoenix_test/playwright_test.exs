defmodule PhoenixTest.PlaywrightTest do
  use PhoenixTest.Case, async: true

  import PhoenixTest

  @moduletag :playwright

  describe "render_page_title/1" do
    test "uses playwright driver by default", %{conn: conn} do
      session = visit(conn, "/live/index")
      assert %PhoenixTest.Playwright{} = session

      title = PhoenixTest.Driver.render_page_title(session)
      assert title == "PhoenixTest is the best!"
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
