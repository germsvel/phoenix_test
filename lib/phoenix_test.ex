defmodule PhoenixTest do
  @moduledoc """
  Documentation for `PhoenixTest`.
  """

  @endpoint Application.compile_env(:phoenix_test, :endpoint)
  import Phoenix.ConnTest
  import ExUnit.Assertions

  def visit(conn, path), do: get(conn, path)

  def click_link(conn, text) do
    path =
      conn
      |> render_html()
      |> find("a", text)
      |> attribute("href")

    visit(conn, path)
  end

  def click_button(conn, text) do
    conn
    |> render_html()
    |> find("a", text)
    |> attribute("href")
  end

  def assert_has(conn, css, text) do
    found =
      conn
      |> render_html()
      |> find(css)
      |> text_content()

    if found == text do
      assert true
    else
      raise "Expected to find #{text} but found #{found} instead"
    end

    conn
  end

  def refute_has(conn, css, text) do
    conn
    |> render_html()
    |> all(css)
    |> case do
      [] ->
        refute false

      elements ->
        if Enum.any?(elements, &element_with_text?(&1, text)) do
          raise "Found element with selector #{inspect(css)} and text #{inspect(text)} when should not be present"
        else
          refute false
        end
    end
  end

  defp element_with_text?(el, text) do
    text_content(el) == text
  end

  defp text_content(element), do: Floki.text(element)

  def attribute(element, attr) do
    element
    |> Floki.attribute(attr)
    |> hd()
  end

  defp find(html, selector, text) do
    elements =
      html
      |> all(selector)

    elements
    |> Enum.find(:not_found, fn element ->
      Floki.text(element) =~ text
    end)
    |> case do
      :not_found ->
        msg = """
          Could not find element with selector #{inspect(selector)} and text #{inspect(text)}.

          Elements with given selector found: #{inspect(Enum.map(elements, &Floki.text/1) |> Enum.join(", "))}
        """

        raise msg

      element ->
        element
    end
  end

  defp find(html, selector) do
    case Floki.find(html, selector) do
      [] -> raise "unable to find element with selector #{inspect(selector)}"
      [element] -> element
      [_, _ | _rest] -> raise "found more than one element with selector #{inspect(selector)}"
    end
  end

  defp all(html, selector) do
    case Floki.find(html, selector) do
      [] -> raise "unable to find element with selector #{inspect(selector)}"
      elements -> elements
    end
  end

  defp render_html(conn) do
    conn
    |> html_response(200)
    |> Floki.parse_document!()
  end
end
