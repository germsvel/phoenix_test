defmodule PhoenixTest.PlaywrightTest do
  use ExUnit.Case, async: true
  use PlaywrightTest.Case

  describe "render_page_title/1" do
    test "renders the page title", %{page: page} do
      title =
        page
        |> PhoenixTest.visit("/page/index")
        |> PhoenixTest.Driver.render_page_title()

      assert title == "PhoenixTest is the best!"
    end
  end
end
