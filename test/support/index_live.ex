defmodule PhoenixTest.IndexLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~H"""
    <h1 id="title" class="title" data-role="title">LiveView main page</h1>

    <.link navigate="/live/page_2">Page 2</.link>
    """
  end
end
