defmodule PhoenixTest.Assertions do
  @moduledoc false

  import ExUnit.Assertions

  alias ExUnit.AssertionError
  alias PhoenixTest.Html
  alias PhoenixTest.Locators
  alias PhoenixTest.Query
  alias PhoenixTest.Utils

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

  def assert_has(session, selector) when is_binary(selector) do
    assert_has(session, selector, count: :any)
  end

  def assert_has(session, locator) do
    html = PhoenixTest.Driver.render_html(session)
    selector = Locators.compile(locator, html)

    assert_has(session, selector)
  end

  def assert_has(session, "title", opts) do
    text = Keyword.fetch!(opts, :text)
    exact = Keyword.get(opts, :exact, false)
    title = PhoenixTest.Driver.render_page_title(session)
    matches? = if exact, do: title == text, else: title =~ text

    if matches? do
      assert true
    else
      raise AssertionError,
        message: """
        Expected title to be #{inspect(text)} but got #{inspect(title)}
        """
    end

    session
  end

  def assert_has(session, selector, opts) when is_list(opts) do
    count = Keyword.get(opts, :count, :any)
    finder = finder_fun(selector, opts)

    session
    |> PhoenixTest.Driver.render_html()
    |> finder.()
    |> case do
      :not_found ->
        raise AssertionError, assert_not_found_error_msg(selector, opts)

      {:not_found, potential_matches} ->
        raise AssertionError,
          message: assert_not_found_error_msg(selector, opts, potential_matches)

      {:found, found} ->
        if count in [:any, 1] do
          assert true
        else
          raise AssertionError,
            message: assert_incorrect_count_error_msg(selector, opts, [found])
        end

      {:found_many, found} ->
        found_count = Enum.count(found)

        if count in [:any, found_count] do
          assert true
        else
          raise AssertionError,
            message: assert_incorrect_count_error_msg(selector, opts, found)
        end
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

  def refute_has(session, selector) when is_binary(selector) do
    refute_has(session, selector, count: :any)
  end

  def refute_has(session, "title", opts) do
    text = Keyword.fetch!(opts, :text)
    exact = Keyword.get(opts, :exact, false)
    title = PhoenixTest.Driver.render_page_title(session)
    matches? = if exact, do: title == text, else: title =~ text

    if matches? do
      raise AssertionError,
        message: """
        Expected title not to be #{inspect(text)}
        """
    else
      refute false
    end

    session
  end

  def refute_has(session, selector, opts) when is_list(opts) do
    count = Keyword.get(opts, :count, :any)
    finder = finder_fun(selector, opts)

    session
    |> PhoenixTest.Driver.render_html()
    |> finder.()
    |> case do
      :not_found ->
        refute false

      {:not_found, _} ->
        refute false

      {:found, element} ->
        if count in [:any, 1] do
          raise AssertionError, message: refute_found_error_msg(selector, opts, [element])
        else
          refute false
        end

      {:found_many, elements} ->
        found_count = Enum.count(elements)

        if count in [:any, found_count] do
          raise AssertionError, message: refute_found_error_msg(selector, opts, elements)
        else
          refute false
        end
    end

    session
  end

  def assert_path(session, path) do
    uri = URI.parse(PhoenixTest.Driver.current_path(session))

    if uri.path == path do
      assert true
    else
      msg = """
      Expected path to be #{inspect(path)} but got #{inspect(uri.path)}
      """

      raise AssertionError, msg
    end

    session
  end

  def assert_path(session, path, opts) do
    params = Keyword.get(opts, :query_params)

    session
    |> assert_path(path)
    |> assert_query_params(params)
  end

  defp assert_query_params(session, params) do
    params = Utils.stringify_keys_and_values(params)

    uri = URI.parse(PhoenixTest.Driver.current_path(session))
    query_params = uri.query && URI.decode_query(uri.query)

    if query_params == params do
      assert true
    else
      params_string = URI.encode_query(params)

      msg = """
      Expected query params to be #{inspect(params_string)} but got #{inspect(uri.query)}
      """

      raise AssertionError, msg
    end

    session
  end

  def refute_path(session, path) do
    uri = URI.parse(PhoenixTest.Driver.current_path(session))

    if uri.path == path do
      msg = """
      Expected path not to be #{inspect(path)}
      """

      raise AssertionError, msg
    else
      refute false
    end

    session
  end

  def refute_path(session, path, opts) do
    params = Keyword.get(opts, :query_params)

    refute_query_params(session, params) || refute_path(session, path)
  end

  defp refute_query_params(session, params) do
    params = Utils.stringify_keys_and_values(params)

    uri = URI.parse(PhoenixTest.Driver.current_path(session))
    query_params = uri.query && URI.decode_query(uri.query)

    if query_params == params do
      params_string = URI.encode_query(params)

      msg = """
      Expected query params not to be #{inspect(params_string)}
      """

      raise AssertionError, msg
    else
      refute false
    end

    session
  end

  defp assert_incorrect_count_error_msg(selector, opts, found) do
    text = Keyword.get(opts, :text, :no_text)
    expected_count = Keyword.get(opts, :count, :any)

    "Expected #{expected_count} elements with #{inspect(selector)}"
    |> maybe_append_text(text)
    |> append_found(found)
  end

  def assert_not_found_error_msg(selector, opts, other_matches \\ []) do
    count = Keyword.get(opts, :count, :any)
    position = Keyword.get(opts, :at, :any)
    text = Keyword.get(opts, :text, :no_text)

    "Could not find #{count} elements with selector #{inspect(selector)}"
    |> maybe_append_text(text)
    |> maybe_append_position(position)
    |> append_found_other_matches(selector, other_matches)
  end

  def refute_found_error_msg(selector, opts, found) do
    refute_count = Keyword.get(opts, :count, :any)
    at = Keyword.get(opts, :at, :any)
    text = Keyword.get(opts, :text, :no_text)

    "Expected not to find #{refute_count} elements with selector #{inspect(selector)}"
    |> maybe_append_text(text)
    |> maybe_append_position(at)
    |> append_found(found)
  end

  defp append_found(msg, found) do
    msg <> "\n\n" <> "But found #{Enum.count(found)}:" <> "\n\n" <> format_found_elements(found)
  end

  defp append_found_other_matches(msg, _selector, []), do: msg

  defp append_found_other_matches(msg, selector, matches) do
    msg <>
      "\n\n" <>
      "Found these elements matching the selector #{inspect(selector)}:" <>
      "\n\n" <> format_found_elements(matches)
  end

  defp maybe_append_text(msg, :no_text), do: msg
  defp maybe_append_text(msg, text), do: msg <> " and text #{inspect(text)}"

  defp maybe_append_position(msg, :any), do: msg
  defp maybe_append_position(msg, position), do: msg <> " at position #{position}"

  defp finder_fun(selector, opts) do
    case Keyword.get(opts, :text, :no_text) do
      :no_text ->
        &Query.find(&1, selector, opts)

      text ->
        &Query.find(&1, selector, text, opts)
    end
  end

  defp format_found_elements(elements) when is_list(elements) do
    Enum.map_join(elements, "\n", &Html.raw/1)
  end

  defp format_found_elements(element), do: format_found_elements([element])
end
