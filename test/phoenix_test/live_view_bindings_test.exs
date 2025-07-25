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

      [element] = html |> Html.parse() |> Html.all("input")

      assert LiveViewBindings.phx_click?(element)
    end

    test "returns false if field doesn't have a phx-click handler" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <input value="Hello world" />
        """)

      [element] = html |> Html.parse() |> Html.all("input")

      refute LiveViewBindings.phx_click?(element)
    end

    test "returns true if JS command is a push (LiveViewTest can handle)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <input phx-click={JS.push("save")} />
        """)

      [element] = html |> Html.parse() |> Html.all("input")

      assert LiveViewBindings.phx_click?(element)
    end

    test "returns true if JS command is a navigate (LiveViewTest can handle)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <input phx-click={JS.navigate("save")} />
        """)

      [element] = html |> Html.parse() |> Html.all("input")

      assert LiveViewBindings.phx_click?(element)
    end

    test "returns true if JS command is a patch (LiveViewTest can handle)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <div phx-click={JS.patch("/some/path")}></div>
        """)

      [element] = html |> Html.parse() |> Html.all("div")

      assert LiveViewBindings.phx_click?(element)
    end

    test "returns false if JS command is a dispatch" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <input phx-click={JS.dispatch("change")} />
        """)

      [element] = html |> Html.parse() |> Html.all("input")

      refute LiveViewBindings.phx_click?(element)
    end

    test "returns true if JS commands include a push or navigate" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <input phx-click={JS.push("save") |> JS.dispatch("change")} />
        """)

      [element] = html |> Html.parse() |> Html.all("input")

      assert LiveViewBindings.phx_click?(element)
    end
  end
end
