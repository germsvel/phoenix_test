defmodule PhoenixTest.LiveViewTimeout do
  @moduledoc false

  alias ExUnit.AssertionError
  alias PhoenixTest.Live

  def with_timeout(%Live{} = session, timeout, action) when timeout <= 0 and is_function(action) do
    action.(session)
  end

  def with_timeout(%Live{} = session, timeout, action) when is_function(action) do
    :ok = PhoenixTest.LiveViewWatcher.watch_view(session.watcher, timeout)
    handle_watched_messages_with_timeout(session, action)
  end

  defp handle_watched_messages_with_timeout(session, action) do
    receive do
      :timeout ->
        dbg(:action_timeout)
        action.(session)

      :live_view_died ->
        dbg(:live_view_died)

        check_for_redirect(session, action)

      :async_process_completed ->
        dbg(:async_process_completed)

        with_retry(session, action, &handle_watched_messages_with_timeout(&1, action))

      {:live_view_redirected, redirect_tuple} ->
        dbg(redirect_tuple)

        session
        |> PhoenixTest.Live.handle_redirect(redirect_tuple)
        |> then(action)
    end
  end

  defp with_retry(session, action, retry_fun) when is_function(action) and is_function(retry_fun) do
    dbg("trying from with_retry")
    action.(session)
  rescue
    AssertionError ->
      dbg("attempt failed. Will retry again")
      retry_fun.(session)
  catch
    :exit, e ->
      dbg({:exit_captured, e})
      retry_fun.(session)
  end

  defp check_for_redirect(session, action) when is_function(action) do
    {path, flash} = Phoenix.LiveViewTest.assert_redirect(session.view, 0)

    session
    |> PhoenixTest.Live.handle_redirect({path, flash})
    |> then(action)
  end
end
