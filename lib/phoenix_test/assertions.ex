defmodule PhoenixTest.Assertions do
  @moduledoc false

  import ExUnit.Assertions

  alias ExUnit.AssertionError
  alias PhoenixTest.Html
  alias PhoenixTest.Query

  @doc """
  Asserts that the rendered HTML content within the given session contains an
  element matching the specified selector and (optional) text.

  ## Parameters

  - `session`: The test session.
  - `selector`: The CSS selector to search for.
  - `text` (optional): The expected text content of the element.

  ## Raises

  Raises `AssertionError` if no element is found with the given selector and text.
  """
  def assert_has(session, "title") do
    title = PhoenixTest.Driver.render_page_title(session)

    if is_nil(title) || title == "" do
      raise AssertionError,
        message: """
        Expected title to be present but could not find it.
        """
    else
      assert true
    end

    session
  end

  def assert_has(session, selector) do
    session
    |> PhoenixTest.Driver.render_html()
    |> Query.find(selector)
    |> case do
      {:found, _found} ->
        assert true

      {:found_many, _found} ->
        assert true

      :not_found ->
        raise AssertionError,
          message: """
          Could not find any elements with selector #{inspect(selector)}.
          """
    end

    session
  end

  def assert_has(session, "title", text) do
    title = PhoenixTest.Driver.render_page_title(session)

    if title == text do
      assert true
    else
      raise AssertionError,
        message: """
        Expected title to be #{inspect(text)} but got #{inspect(title)}
        """
    end

    session
  end

  def assert_has(session, selector, text) do
    session
    |> PhoenixTest.Driver.render_html()
    |> Query.find(selector, text)
    |> case do
      {:found, _found} ->
        assert true

      {:found_many, _found} ->
        assert true

      {:not_found, []} ->
        raise AssertionError,
          message: """
          Could not find any elements with selector #{inspect(selector)}.
          """

      {:not_found, elements_matched_selector} ->
        raise AssertionError,
          message: """
          Could not find element with text #{inspect(text)}.

          Found other elements matching the selector #{inspect(selector)}:

          #{format_found_elements(elements_matched_selector)}
          """
    end

    session
  end

  @doc """
  Asserts that the rendered HTML within the given session does not contain an element matching the specified selector and text.

  ## Parameters

  - `session`: The test session.
  - `selector`: The CSS selector for the element.
  - `text`: The text that the element is expected not to contain.

  ## Raises

  Raises `AssertionError` if an element matching the selector and text is found.
  """
  def refute_has(session, "title") do
    title = PhoenixTest.Driver.render_page_title(session)

    if is_nil(title) do
      refute false
    else
      raise AssertionError,
        message: """
        Expected title not to be present but found: #{inspect(title)}
        """
    end

    session
  end

  def refute_has(session, selector) do
    session
    |> PhoenixTest.Driver.render_html()
    |> Query.find(selector)
    |> case do
      :not_found ->
        refute false

      {:found, element} ->
        raise AssertionError,
          message: """
          Expected not to find an element.

          But found an element with selector #{inspect(selector)}:

          #{format_found_elements(element)}
          """

      {:found_many, elements} ->
        raise AssertionError,
          message: """
          Expected not to find an element.

          But found #{Enum.count(elements)} elements with selector #{inspect(selector)}:

          #{format_found_elements(elements)}
          """
    end

    session
  end

  def refute_has(session, "title", text) do
    title = PhoenixTest.Driver.render_page_title(session)

    if title == text do
      raise AssertionError,
        message: """
        Expected title not to be #{inspect(text)}
        """
    else
      refute false
    end

    session
  end

  def refute_has(session, selector, text) do
    session
    |> PhoenixTest.Driver.render_html()
    |> Query.find(selector, text)
    |> case do
      {:not_found, _} ->
        refute false

      {:found, element} ->
        raise AssertionError,
          message: """
          Expected not to find an element.

          But found an element with selector #{inspect(selector)} and text #{inspect(text)}:

          #{format_found_elements(element)}
          """

      {:found_many, elements} ->
        raise AssertionError,
          message: """
          Expected not to find an element.

          But found #{Enum.count(elements)} elements with selector #{inspect(selector)} and text #{inspect(text)}:

          #{format_found_elements(elements)}
          """
    end

    session
  end

  defp format_found_elements(elements) when is_list(elements) do
    Enum.map_join(elements, "\n", &Html.raw/1)
  end

  defp format_found_elements(element), do: format_found_elements([element])
end
