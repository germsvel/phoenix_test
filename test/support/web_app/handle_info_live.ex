defmodule PhoenixTest.WebApp.HandleInfoLive do
  @moduledoc false
  use Phoenix.LiveView

  def render(assigns) do
    ~H"""
    <a phx-click="redirect-me">Redirect</a>
    <a phx-click="patch-me">Patch</a>
    """
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  def handle_event("redirect-me", _params, socket) do
    send(self(), :redirect_me)
    {:noreply, socket}
  end

  def handle_event("patch-me", _params, socket) do
    send(self(), :patch_me)
    {:noreply, socket}
  end

  def handle_info(:redirect_me, socket) do
    {:noreply, push_navigate(socket, to: "/live/index")}
  end

  def handle_info(:patch_me, socket) do
    {:noreply, push_patch(socket, to: "/live/info_handled")}
  end
end
