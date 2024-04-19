defmodule PhoenixTest.Page2Live do
  @moduledoc false
  use Phoenix.LiveView

  def render(assigns) do
    ~H"""
    <h1>LiveView page 2</h1>
    """
  end

  def mount(%{"redirect_to" => path}, _, socket) do
    {:ok, push_navigate(socket, to: path)}
  end

  def mount(_, _, socket) do
    {:ok, socket}
  end
end
