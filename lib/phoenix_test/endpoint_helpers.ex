defmodule PhoenixTest.EndpointHelpers do
  @moduledoc false

  # This module replaces Phoenix test macros that require `@endpoint` to be set
  # as a compile-time module attribute. Instead, the endpoint is read at runtime
  # from `conn.private[:phoenix_endpoint]`, set via `PhoenixTest.put_endpoint/2`.

  def endpoint_from!(conn) do
    conn.private[:phoenix_endpoint] ||
      Application.get_env(:phoenix_test, :endpoint) ||
      raise ArgumentError, """
      No endpoint set on conn. Use PhoenixTest.put_endpoint/2 in your test setup:

        ```elixir
        conn =
          Phoenix.ConnTest.build_conn()
          |> PhoenixTest.put_endpoint(MyAppWeb.Endpoint)
        ```

      Or configure the endpoint in your test config:

          config :phoenix_test, :endpoint, MyAppWeb.Endpoint
      """
  end

  def endpoint_from(conn) do
    conn.private[:phoenix_endpoint]
  end

  def copy_endpoint(dest_conn, source_conn) do
    Plug.Conn.put_private(dest_conn, :phoenix_endpoint, endpoint_from(source_conn))
  end

  # Replaces: live(conn)
  # The `live/1` macro's binary-path branch calls `get(conn, path)` which
  # requires `@endpoint` at compile time, even when path is nil.
  def live(conn) do
    Phoenix.LiveViewTest.__live__(conn, nil, [])
  end

  # Replaces: follow_redirect(result, conn) for :live_redirect
  def follow_live_redirect(conn, opts) do
    endpoint = endpoint_from!(conn)
    {conn, to} = Phoenix.LiveViewTest.__follow_redirect__(conn, endpoint, nil, opts)

    conn
    |> Phoenix.ConnTest.dispatch(endpoint, :get, to, nil)
    |> Phoenix.LiveViewTest.__live__(to, [])
  end

  # Replaces: follow_redirect(result, conn) for :redirect
  def follow_redirect(conn, opts) do
    endpoint = endpoint_from!(conn)
    {conn, to} = Phoenix.LiveViewTest.__follow_redirect__(conn, endpoint, nil, opts)
    Phoenix.ConnTest.dispatch(conn, endpoint, :get, to, nil)
  end

  # Replaces: file_input(view, form_selector, name, entries)
  # The `file_input/4` macro calls `Phoenix.ChannelTest.connect/2` which
  # requires `@endpoint` at compile time.
  def file_input(view, conn, form_selector, name, entries) do
    endpoint = endpoint_from!(conn)
    builder = fn -> Phoenix.ChannelTest.__connect__(endpoint, Phoenix.LiveView.Socket, %{}, []) end
    Phoenix.LiveViewTest.__file_input__(view, form_selector, name, entries, builder)
  end
end
