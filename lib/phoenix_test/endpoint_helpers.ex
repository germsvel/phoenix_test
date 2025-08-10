defmodule PhoenixTest.EndpointHelpers do
  @moduledoc false

  @endpoint Application.compile_env(:phoenix_test, :endpoint)

  def current_endpoint() do
    current_app = Mix.Project.config()[:app]

    if is_nil(current_app) do
      raise "could not find `:app` in the Mix `project` keyword list. Define `app: my_app` in the project's mix.exs file."
    end

    Application.fetch_env(:phoenix_test, :endpoints)
    |> case do
      {:ok, endpoints} -> 
        Access.fetch(endpoints, current_app)
        |> case do
          {:ok, endpoint} -> endpoint
          :error -> raise "could not find `#{current_app}` under `:phoenix_test, :endpoint` in the project config. Please set the endpoint for this app."
        end

      :error ->
        case @endpoint do
          nil -> raise "no endpoint set to be used by `:phoenix_test`. Please add to the project config either a global endpoint under `:phoenix_test, :endpoint` or a map with the endpoint to be used by each app under `:phoenix_test, :endpoint`."
          _ -> @endpoint
        end
    end
  end

  def live_with_current_endpoint(conn, path \\ nil, opts \\ []) do
    cond do
        is_binary(path) ->
          Phoenix.LiveViewTest.__live__(dispatch(conn, Utils.current_endpoint(), :get, path), path, opts)

        is_nil(path) ->
          Phoenix.LiveViewTest.__live__(conn, nil, opts)

        true ->
          raise RuntimeError, "path must be nil or a binary, got: #{inspect(path)}"
      end
  end

  def follow_redirect_with_current_endpoint(reason, conn, to \\ nil) do
    endpoint = Utils.current_endpoint()

    case reason do
      {:error, {:live_redirect, opts}} ->
        {conn, to} = Phoenix.LiveViewTest.__follow_redirect__(conn, endpoint, to, opts)
        live_with_current_endpoint(conn, to)

      {:error, {:redirect, opts}} ->
        {conn, to} = Phoenix.LiveViewTest.__follow_redirect__(conn, endpoint, to, opts)
        {:ok, dispatch(conn, endpoint, :get, to)}

      _ ->
        raise "LiveView did not redirect"
    end
  end

  def file_input_with_current_endpoint(view, form_selector, name, entries) do
    builder = fn -> Phoenix.ChannelTest.__connect__(EndpointHelpers.current_endpoint(), Phoenix.LiveView.Socket, %{}, []) end

    Phoenix.LiveViewTest.__file_input__(view, form_selector, name, entries, builder)
  end
end
