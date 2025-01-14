defmodule PhoenixTest.LiveViewTimeout do
  @moduledoc false

  alias ExUnit.AssertionError
  alias PhoenixTest.Live
  alias PhoenixTest.Static

  def with_timeout(%Static{} = session, _timeout, action) when is_function(action) do
    action.(session)
  end

  def with_timeout(%Live{} = session, timeout, action) when timeout <= 0 and is_function(action) do
    action.(session)
  end

  def with_timeout(%Live{} = session, timeout, action) when is_function(action) do
    :ok = PhoenixTest.LiveViewWatcher.watch_view(session.watcher, session.view, timeout)
    handle_watched_messages_with_timeout(session, action)
  end

  defp handle_watched_messages_with_timeout(session, action) do
    view_pid = session.view.pid

    receive do
      {:watcher, ^view_pid, {:live_view_redirected, redirect_tuple, timeout_left}} ->
        session
        |> PhoenixTest.Live.handle_redirect(redirect_tuple)
        |> with_timeout(timeout_left, action)

      {:watcher, ^view_pid, :live_view_died} ->
        check_for_redirect(session, action)

      {:watcher, ^view_pid, :async_process_completed} ->
        with_retry(session, action, &handle_watched_messages_with_timeout(&1, action))

      {:watcher, ^view_pid, :timeout} ->
        action.(session)
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

  defp check_for_redirect(session, action) when is_function(action) do
    {path, flash} = Phoenix.LiveViewTest.assert_redirect(session.view, 0)

    session
    |> PhoenixTest.Live.handle_redirect({:redirect, %{to: path, flash: flash}})
    |> then(action)
  end
end
