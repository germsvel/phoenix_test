defmodule PhoenixTest.LiveViewBindingsTest do
  use ExUnit.Case, async: true

  import Phoenix.Component
  import Phoenix.LiveViewTest

  alias Phoenix.LiveView.JS
  alias PhoenixTest.Html
  alias PhoenixTest.LiveViewBindings

  describe "phx_click?" do
    test "returns true if parsed element has a phx-click handler" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <input phx-click="save" />
        """)

      element = html |> Html.parse_fragment() |> Html.all("input")

      assert LiveViewBindings.phx_click?(element)
    end

    test "returns false if field doesn't have a phx-click handler" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <input value="Hello world" />
        """)

      element = html |> Html.parse_fragment() |> Html.all("input")

      refute LiveViewBindings.phx_click?(element)
    end

    test "returns true if JS command is a push (LiveViewTest can handle)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <input phx-click={JS.push("save")} />
        """)

      element = html |> Html.parse_fragment() |> Html.all("input")

      assert LiveViewBindings.phx_click?(element)
    end

    test "returns true if JS command is a navigate (LiveViewTest can handle)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <input phx-click={JS.navigate("save")} />
        """)

      element = html |> Html.parse_fragment() |> Html.all("input")

      assert LiveViewBindings.phx_click?(element)
    end

    test "returns true if JS command is a patch (LiveViewTest can handle)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <div phx-click={JS.patch("/some/path")}></div>
        """)

      element = html |> Html.parse_fragment() |> Html.all("div")

      assert LiveViewBindings.phx_click?(element)
    end

    test "returns false if JS command is a dispatch" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <input phx-click={JS.dispatch("change")} />
        """)

      element = html |> Html.parse_fragment() |> Html.all("input")

      refute LiveViewBindings.phx_click?(element)
    end

    test "returns true if JS commands include a push or navigate" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <input phx-click={JS.push("save") |> JS.dispatch("change")} />
        """)

      element = html |> Html.parse_fragment() |> Html.all("input")

      assert LiveViewBindings.phx_click?(element)
    end
  end

  describe "phx_click_action/1" do
    test "returns :render_click for plain phx-click event names" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <button phx-click="save">Save</button>
        """)

      element = html |> Html.parse_fragment() |> Html.all("button")

      assert LiveViewBindings.phx_click_action(element) == :render_click
    end

    test "returns :dispatch_change for JS.dispatch(change) only" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <button phx-click={JS.dispatch("change")}>Add</button>
        """)

      element = html |> Html.parse_fragment() |> Html.all("button")

      assert LiveViewBindings.phx_click_action(element) == :dispatch_change
    end

    test "returns :render_click when JS includes push and dispatch(change)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <button phx-click={JS.push("save") |> JS.dispatch("change")}>Save</button>
        """)

      element = html |> Html.parse_fragment() |> Html.all("button")

      assert LiveViewBindings.phx_click_action(element) == :render_click
    end

    test "returns :none when phx-click is absent" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <button>No action</button>
        """)

      element = html |> Html.parse_fragment() |> Html.all("button")

      assert LiveViewBindings.phx_click_action(element) == :none
    end
  end
end
