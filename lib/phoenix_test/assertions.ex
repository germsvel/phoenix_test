defmodule PhoenixTest.Assertions do
  @moduledoc false

  import ExUnit.Assertions

  alias ExUnit.AssertionError
  alias Phoenix.HTML.Safe
  alias PhoenixTest.Html
  alias PhoenixTest.Operation
  alias PhoenixTest.Query
  alias PhoenixTest.Utils

  defmodule Opts do
    @moduledoc false
    defstruct [
      :at,
      :count,
      :exact,
      :label,
      :text,
      :value
    ]

    def parse(opts) when is_list(opts) do
      at = Keyword.get(opts, :at, :any)
      count = Keyword.get(opts, :count, :any)
      exact = Keyword.get(opts, :exact, false)
      label = Keyword.get(opts, :label, :no_label)
      text = Keyword.get(opts, :text, :no_text)
      value = Keyword.get(opts, :value, :no_value)

      %__MODULE__{
        at: at,
        count: count,
        exact: exact,
        label: label,
        text: text,
        value: value
      }
    end

    def to_list(%__MODULE__{} = opts) do
      [
        at: opts.at,
        count: opts.count,
        exact: opts.exact,
        label: opts.label,
        text: opts.text,
        value: opts.value
      ]
    end
  end

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
    session = set_operation(session, :assert_has, title)

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

  def assert_has(session, "title", opts) do
    text = Keyword.fetch!(opts, :text)
    exact = Keyword.get(opts, :exact, false)
    title = PhoenixTest.Driver.render_page_title(session)
    session = set_operation(session, :assert_has, title)
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

  @label_related_failures [:no_label, :missing_for, :missing_input]
  def assert_has(session, selector, opts) when is_list(opts) do
    opts = Opts.parse(opts)
    finder = finder_fun(selector, opts)
    session = set_operation(session, :assert_has)

    case finder.(session.current_operation.html) do
      :not_found ->
        raise AssertionError, assert_not_found_error_msg(selector, opts)

      {:not_found, potential_matches} ->
        raise AssertionError,
          message: assert_not_found_error_msg(selector, opts, potential_matches)

      {:not_found, failure, potential_matches} when failure in @label_related_failures ->
        raise AssertionError,
          message: assert_not_found_error_msg(selector, opts, potential_matches)

      {:not_found, :found_many_labels_with_inputs, _label_elements, found} ->
        found_count = Enum.count(found)

        if opts.count in [:any, found_count] do
          assert true
        else
          raise AssertionError,
            message: assert_incorrect_count_error_msg(selector, opts, found)
        end

      {:found, found} ->
        if opts.count in [:any, 1] do
          assert true
        else
          raise AssertionError,
            message: assert_incorrect_count_error_msg(selector, opts, [found])
        end

      {:found_many, found} ->
        found_count = Enum.count(found)

        if opts.count in [:any, found_count] do
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
    session = set_operation(session, :refute_has, title)

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
    session = set_operation(session, :refute_has, title)
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
    opts = Opts.parse(opts)
    finder = finder_fun(selector, opts)
    session = set_operation(session, :refute_has)

    case finder.(session.current_operation.html) do
      :not_found ->
        refute false

      {:not_found, _} ->
        refute false

      {:not_found, failure, _} when failure in @label_related_failures ->
        refute false

      {:not_found, :found_many_labels_with_inputs, _labels, elements} ->
        found_count = Enum.count(elements)

        if opts.count in [:any, found_count] do
          raise AssertionError, message: refute_found_error_msg(selector, opts, elements)
        else
          refute false
        end

      {:found, element} ->
        if opts.count in [:any, 1] do
          raise AssertionError, message: refute_found_error_msg(selector, opts, [element])
        else
          refute false
        end

      {:found_many, elements} ->
        found_count = Enum.count(elements)

        if opts.count in [:any, found_count] do
          raise AssertionError, message: refute_found_error_msg(selector, opts, elements)
        else
          refute false
        end
    end

    session
  end

  def assert_path(session, path) do
    session = set_operation(session, :assert_path, "")
    uri = URI.parse(PhoenixTest.Driver.current_path(session))

    if path_matches?(path, uri.path) do
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

  defp path_matches?(path, path), do: true

  defp path_matches?(expected, is) do
    parts_expected = String.split(expected, "/")
    parts_is = String.split(is, "/")

    if Enum.count(parts_expected) != Enum.count(parts_is) do
      false
    else
      parts_not_matching =
        parts_expected
        |> Enum.zip(parts_is)
        |> Enum.filter(fn {expect, is} -> uri_parts_match?(expect, is) == false end)

      parts_not_matching == []
    end
  end

  def uri_parts_match?("*", _), do: true
  def uri_parts_match?(part, part), do: true
  def uri_parts_match?(_a, _b), do: false

  defp assert_query_params(session, params) do
    params = Utils.stringify_keys_and_values(params)

    uri = URI.parse(PhoenixTest.Driver.current_path(session))
    query_params = uri.query && Plug.Conn.Query.decode(uri.query)

    cond do
      query_params == params ->
        assert true

      is_nil(query_params) && params == %{} ->
        assert true

      true ->
        params_string = Plug.Conn.Query.encode(params)

        msg = """
        Expected query params to be #{inspect(params_string)} but got #{inspect(uri.query)}
        """

        raise AssertionError, msg
    end

    session
  end

  def refute_path(session, path) do
    session = set_operation(session, :refute_path, "")
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
    session = set_operation(session, :refute_path, "")
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
    "Expected #{count_elements(opts.count)} with #{inspect(selector)}"
    |> maybe_append_text(opts.text)
    |> maybe_append_value(opts.value)
    |> maybe_append_label(opts.label)
    |> append_found(found)
  end

  defp assert_not_found_error_msg(selector, opts, other_matches \\ []) do
    "Could not find #{count_elements(opts.count)} with selector #{inspect(selector)}"
    |> maybe_append_text(opts.text)
    |> maybe_append_value(opts.value)
    |> maybe_append_label(opts.label)
    |> maybe_append_position(opts.at)
    |> append_found_other_matches(selector, other_matches)
  end

  def refute_found_error_msg(selector, opts, found) do
    "Expected not to find #{count_elements(opts.count)} with selector #{inspect(selector)}"
    |> maybe_append_text(opts.text)
    |> maybe_append_value(opts.value)
    |> maybe_append_label(opts.label)
    |> maybe_append_position(opts.at)
    |> append_found(found)
  end

  defp count_elements(1), do: "1 element"
  defp count_elements(count), do: "#{count} elements"

  defp append_found(msg, found) do
    msg <> "\n\n" <> "But found #{Enum.count(found)}:" <> "\n\n" <> format_found_elements(found)
  end

  defp append_found_other_matches(msg, selector, matches) do
    if Enum.empty?(matches) do
      msg
    else
      msg <>
        "\n\n" <>
        "Found these elements matching the selector #{inspect(selector)}:" <>
        "\n\n" <> format_found_elements(matches)
    end
  end

  defp maybe_append_text(msg, :no_text), do: msg
  defp maybe_append_text(msg, text), do: msg <> " and text #{inspect(text)}"

  defp maybe_append_value(msg, :no_value), do: msg
  defp maybe_append_value(msg, value), do: msg <> " and value #{inspect(value)}"

  defp maybe_append_label(msg, :no_label), do: msg
  defp maybe_append_label(msg, label), do: msg <> " with label #{inspect(label)}"

  defp maybe_append_position(msg, :any), do: msg
  defp maybe_append_position(msg, position), do: msg <> " at position #{position}"

  defp finder_fun(selector, %Opts{} = opts) do
    case {opts.text, opts.value} do
      {:no_text, :no_value} ->
        &Query.find(&1, selector, Opts.to_list(opts))

      {:no_text, value} ->
        value_finder_fun(ensure_binary(value), selector, opts)

      {text, :no_value} ->
        &Query.find(&1, selector, ensure_binary(text), Opts.to_list(opts))

      {_text, _value} ->
        raise ArgumentError, "Cannot provide both :text and :value to assertions"
    end
  end

  defp value_finder_fun(value, selector, %Opts{} = opts) do
    selector = selector <> "[value=#{inspect(value)}]"

    case opts.label do
      :no_label ->
        &Query.find(&1, selector, Opts.to_list(opts))

      label when is_binary(label) ->
        &Query.find_by_label(&1, selector, label, Opts.to_list(opts))
    end
  end

  defp ensure_binary(value) when is_binary(value), do: value

  defp ensure_binary(value) do
    value |> Safe.to_iodata() |> IO.iodata_to_binary()
  end

  defp format_found_elements(elements) when is_list(elements) do
    Enum.map_join(elements, "\n", &Html.raw/1)
  end

  defp format_found_elements(element), do: format_found_elements([element])

  defp set_operation(session, name, rendered_html \\ nil) do
    html = rendered_html || PhoenixTest.Driver.render_html(session)
    Map.put(session, :current_operation, Operation.new(name, html))
  end
end
