defmodule PhoenixTest.LiveViewTimeout do
  @moduledoc false

  alias ExUnit.AssertionError
  alias PhoenixTest.Live
  alias PhoenixTest.Static

  def interval_wait_time do
    case Application.get_env(:phoenix_test, :timeout_interval_wait_time, 100) do
      interval when is_integer(interval) and interval > 0 -> interval
      other -> raise ArgumentError, ":timeout_interval_wait_time must be a positive integer, got: #{inspect(other)}"
    end
  end

  def with_timeout(session, timeout, action, fetch_redirect_info \\ &via_assert_redirect/1)

  def with_timeout(%Static{} = session, _timeout, action, _fetch_redirect_info) when is_function(action) do
    action.(session)
  end

  def with_timeout(%Live{} = session, timeout, action, _fetch_redirect_info) when timeout <= 0 and is_function(action) do
    action.(session)
  end

  def with_timeout(%Live{} = session, timeout, action, fetch_redirect_info) when is_function(action) do
    :ok = PhoenixTest.LiveViewWatcher.watch_view(session.watcher, session.view)
    handle_watched_messages_with_timeout(session, timeout, action, fetch_redirect_info)
  end

  defp handle_watched_messages_with_timeout(session, timeout, action, fetch_redirect_info) when timeout <= 0 do
    action.(session)
  catch
    :exit, _e ->
      check_for_redirect(session, action, fetch_redirect_info)
  end

  defp handle_watched_messages_with_timeout(session, timeout, action, fetch_redirect_info) do
    wait_time = min(timeout, interval_wait_time())
    new_timeout = timeout - wait_time
    view_pid = session.view.pid

    receive do
      {:watcher, ^view_pid, {:live_view_redirected, redirect_tuple}} ->
        session
        |> PhoenixTest.Live.handle_redirect(redirect_tuple)
        |> with_timeout(new_timeout, action, fetch_redirect_info)

      {:watcher, ^view_pid, :live_view_died} ->
        check_for_redirect(session, action, fetch_redirect_info)
    after
      wait_time ->
        with_retry(session, action, &handle_watched_messages_with_timeout(&1, new_timeout, action, fetch_redirect_info))
    end
  end

  defp with_retry(session, action, retry_fun) when is_function(action) and is_function(retry_fun) do
    :ok = Phoenix.LiveView.Channel.ping(session.view.pid)
    action.(session)
  rescue
    AssertionError ->
      retry_fun.(session)
  catch
    :exit, _e ->
      retry_fun.(session)
  end

  defp check_for_redirect(session, action, fetch_redirect_info) when is_function(action) do
    {path, flash} = fetch_redirect_info.(session)

    session
    |> PhoenixTest.Live.handle_redirect({:redirect, %{to: path, flash: flash}})
    |> then(action)
  end

  defp via_assert_redirect(session) do
    Phoenix.LiveViewTest.assert_redirect(session.view)
  end
end
