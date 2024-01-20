defmodule PhoenixTest.LiveTest do
  use ExUnit.Case, async: true

  import PhoenixTest

  alias PhoenixTest.Driver

  setup do
    %{conn: Phoenix.ConnTest.build_conn()}
  end

  describe "visit/2" do
    test "navigates to given LiveView page", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> assert_has("h1", "LiveView main page")
    end
  end

  describe "click_link/2" do
    test "follows 'navigate' links", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> click_link("Navigate link")
      |> assert_has("h1", "LiveView page 2")
    end

    test "handles patches to current view", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> click_link("Patch link")
      |> assert_has("h2", "LiveView main page details")
    end

    test "handles navigation to a non-liveview", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> click_link("Navigate to non-liveview")
      |> assert_has("h1", "Main page")
    end

    test "raises error when there are multiple links with same text", %{conn: conn} do
      assert_raise ArgumentError, ~r/2 of them matched the text filter/, fn ->
        conn
        |> visit("/live/index")
        |> click_link("Multiple links")
      end
    end
  end

  describe "click_button/2" do
    test "handles a `phx-click` button", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> click_button("Show tab")
      |> assert_has("#tab", "Tab title")
    end
  end

  describe "fill_form/3" do
    test "does not trigger phx-change event if one isn't present", %{conn: conn} do
      session = conn |> visit("/live/index")

      starting_html = Driver.render_html(session)

      ending_html =
        session
        |> fill_form("#no-phx-change-form", name: "Aragorn")
        |> Driver.render_html()

      assert starting_html == ending_html
    end

    test "triggers a phx-change event on a form (when it has one)", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_form("#email-form", email: nil)
      |> assert_has("#form-errors", "Errors present")
    end

    test "can be combined with click_button to submit a form", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> fill_form("#email-form", email: "some@example.com")
      |> click_button("Save")
      |> assert_has("#form-data", "email: some@example.com")
    end
  end

  describe "submit_form/3" do
    test "submits a form via phx-submit", %{conn: conn} do
      conn
      |> visit("/live/index")
      |> submit_form("#email-form", email: "some@example.com")
      |> assert_has("#form-data", "email: some@example.com")
    end
  end
end
