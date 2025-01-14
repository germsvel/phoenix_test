defmodule PhoenixTest.WebApp.AsyncPage2Live do
  @moduledoc false
  use Phoenix.LiveView

  def mount(_, _, socket) do
    {:ok,
     assign_async(socket, :title, fn ->
       Process.sleep(100)
       {:ok, %{title: "Another title loaded async"}}
     end)}
  end

  def render(assigns) do
    ~H"""
    <.async_result :let={title} assign={@title}>
      <:loading>Loading title...</:loading>
      <:failed :let={_failure}>there was an error loading the title</:failed>
      <h1>{title}</h1>
    </.async_result>
    """
  end
end
