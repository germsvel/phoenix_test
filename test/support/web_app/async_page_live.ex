defmodule PhoenixTest.WebApp.AsyncPageLive do
  @moduledoc false
  use Phoenix.LiveView

  def mount(_, _, socket) do
    {:ok,
     socket
     |> assign(:h2, "Where we test LiveView's async behavior")
     |> assign_async(:title, fn ->
       Process.sleep(100)
       {:ok, %{title: "Title loaded async"}}
     end)}
  end

  def render(assigns) do
    ~H"""
    <.async_result :let={title} assign={@title}>
      <:loading>Loading title...</:loading>
      <:failed :let={_failure}>there was an error loading the title</:failed>
      <h1>{title}</h1>
    </.async_result>

    <h2>
      {@h2}
    </h2>

    <button phx-click="change-h2">
      Change h2
    </button>

    <button phx-click="async-navigate">
      Async navigate!
    </button>

    <button phx-click="async-navigate-to-async">
      Async navigate to async 2 page!
    </button>

    <button phx-click="async-navigate-quickly">
      Navigate quickly
    </button>

    <button phx-click="async-redirect">
      Async redirect!
    </button>
    """
  end

  def handle_event("change-h2", _, socket) do
    Process.send_after(self(), :change_h2, 100)
    {:noreply, socket}
  end

  def handle_event("async-navigate-quickly", _, socket) do
    {:noreply,
     start_async(socket, :async_navigate_quickly, fn ->
       :ok
     end)}
  end

  def handle_event("async-navigate", _, socket) do
    {:noreply,
     start_async(socket, :async_navigate, fn ->
       Process.sleep(100)
       :ok
     end)}
  end

  def handle_event("async-navigate-to-async", _, socket) do
    {:noreply,
     start_async(socket, :async_navigate_to_async, fn ->
       Process.sleep(100)
       :ok
     end)}
  end

  def handle_event("async-redirect", _, socket) do
    {:noreply,
     start_async(socket, :async_redirect, fn ->
       Process.sleep(100)
       :ok
     end)}
  end

  def handle_async(:async_navigate_quickly, {:ok, _result}, socket) do
    {:noreply, push_navigate(socket, to: "/live/page_2")}
  end

  def handle_async(:async_navigate, {:ok, _result}, socket) do
    {:noreply, push_navigate(socket, to: "/live/page_2")}
  end

  def handle_async(:async_navigate_to_async, {:ok, _result}, socket) do
    {:noreply, push_navigate(socket, to: "/live/async_page_2")}
  end

  def handle_async(:async_redirect, {:ok, _result}, socket) do
    Process.sleep(100)
    {:noreply, redirect(socket, to: "/page/index")}
  end

  def handle_info(:change_h2, socket) do
    {:noreply, assign(socket, :h2, "I've been changed!")}
  end
end
