defmodule PhoenixTest.Butterbee do
  @moduledoc false

  import ExUnit.Assertions

  alias PhoenixTest.OpenBrowser

  require Logger

  defstruct [:driver]

  @doc false
  def build do
    driver = :butterbee@driver.new(:firefox)
    %__MODULE__{driver: driver}
  end

  @doc false
  def close(conn) do
    dbg(conn)
    :butterbee@driver.close(conn.driver)

    conn
  end

  @doc false
  def visit(conn, path) do
    url =
      case path do
        "http://" <> _ -> path
        "https://" <> _ -> path
        _ -> Application.fetch_env!(:phoenix_test, :base_url) <> path
      end

    Map.update!(conn, :driver, &:butterbee@driver.goto(&1, url))
  end

  def assert_path(conn, path, opts \\ []), do: raise("not implemented")
  def refute_path(conn, path, opts \\ []), do: raise("not implemented")

  def assert_has(conn, "title"), do: raise("not implemented")
  def assert_has(conn, selector), do: assert_has(conn, selector, [])
  def assert_has(conn, "title", opts), do: raise("not implemented")

  def assert_has(conn, selector, text: expected) do
    Map.update!(conn, :driver, fn driver ->
      driver =
        conn.driver |> :butterbee@get.node(:butterbee@by.css(selector)) |> :butterbee@node.get(:butterbee@node.text())

      {:ok, text} = :butterbee@driver.value(driver)
      assert text == expected

      driver
    end)
  end

  def refute_has(conn, "title"), do: raise("not implemented")
  def refute_has(conn, selector), do: refute_has(conn, selector, [])
  def refute_has(conn, "title", opts), do: raise("not implemented")
  def refute_has(conn, selector, opts), do: raise("not implemented")

  def render_page_title(conn), do: raise("not implemented")
  def render_html(conn), do: raise("not implemented")

  def click_link(conn, selector \\ nil, text), do: raise("not implemented")
  def click_button(conn, selector \\ nil, text), do: raise("not implemented")
  def fill_in(conn, css_selector \\ nil, label, opts), do: raise("not implemented")
  def select(conn, css_selector \\ nil, option_labels, opts), do: raise("not implemented")
  def check(conn, css_selector \\ nil, label, opts), do: raise("not implemented")
  def uncheck(conn, css_selector \\ nil, label, opts), do: raise("not implemented")
  def choose(conn, css_selector \\ nil, label, opts), do: raise("not implemented")
  def upload(conn, css_selector \\ nil, label, paths, opts), do: raise("not implemented")
  def submit(conn), do: raise("not implemented")
  def open_browser(conn, open_fun \\ &OpenBrowser.open_with_system_cmd/1), do: raise("not implemented")
  def unwrap(conn, fun), do: raise("not implemented")
  def current_path(conn), do: raise("not implemented")
end

defimpl PhoenixTest.Driver, for: PhoenixTest.Butterbee do
  alias PhoenixTest.Butterbee

  defdelegate visit(conn, path), to: Butterbee
  defdelegate render_page_title(conn), to: Butterbee
  defdelegate render_html(conn), to: Butterbee
  defdelegate within(conn, selector, fun), to: PhoenixTest.SessionHelpers
  defdelegate click_link(conn, text), to: Butterbee
  defdelegate click_link(conn, selector, text), to: Butterbee
  defdelegate click_button(conn, text), to: Butterbee
  defdelegate click_button(conn, selector, text), to: Butterbee
  defdelegate fill_in(conn, label, opts), to: Butterbee
  defdelegate fill_in(conn, selector, label, opts), to: Butterbee
  defdelegate select(conn, selector, option, opts), to: Butterbee
  defdelegate select(conn, option, opts), to: Butterbee
  defdelegate check(conn, selector, label, opts), to: Butterbee
  defdelegate check(conn, label, opts), to: Butterbee
  defdelegate uncheck(conn, selector, label, opts), to: Butterbee
  defdelegate uncheck(conn, label, opts), to: Butterbee
  defdelegate choose(conn, selector, label, opts), to: Butterbee
  defdelegate choose(conn, label, opts), to: Butterbee
  defdelegate upload(conn, selector, label, path, opts), to: Butterbee
  defdelegate upload(conn, label, path, opts), to: Butterbee
  defdelegate submit(conn), to: Butterbee
  defdelegate open_browser(conn), to: Butterbee
  defdelegate open_browser(conn, open_fun), to: Butterbee
  defdelegate unwrap(conn, fun), to: Butterbee
  defdelegate current_path(conn), to: Butterbee

  defdelegate assert_has(conn, selector), to: Butterbee
  defdelegate assert_has(conn, selector, opts), to: Butterbee
  defdelegate refute_has(conn, selector), to: Butterbee
  defdelegate refute_has(conn, selector, opts), to: Butterbee

  defdelegate assert_path(conn, path), to: Butterbee
  defdelegate assert_path(conn, path, opts), to: Butterbee
  defdelegate refute_path(conn, path), to: Butterbee
  defdelegate refute_path(conn, path, opts), to: Butterbee
end
