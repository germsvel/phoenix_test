defmodule PhoenixTest.Html do
  def parse(html) do
    html
    |> Floki.parse_document!()
  end

  def text_content(element), do: Floki.text(element) |> String.trim()

  def attribute(element, attr) do
    element
    |> Floki.attribute(attr)
    |> hd()
  end

  def find(html, selector, text) do
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

  def find(html, selector) do
    case Floki.find(html, selector) do
      [] -> raise "Could not find element with selector #{inspect(selector)}"
      [element] -> element
      [_, _ | _rest] -> raise "Found more than one element with selector #{inspect(selector)}"
    end
  end

  def all(html, selector) do
    Floki.find(html, selector)
  end
end
