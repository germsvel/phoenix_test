defmodule PhoenixTest.WebApp.ChildLive do
  @moduledoc false
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :form_data, %{})}
  end

  def render(assigns) do
    ~H"""
    <h1>Child LiveView</h1>

    <form phx-submit="save-form">
      <label>
        Email <input type="email" name="email" />
      </label>

      <button type="submit">Save</button>
    </form>

    <div id="child-view-form-data">
      <%= for {key, value} <- @form_data do %>
        {key}: {value}
      <% end %>
    </div>
    """
  end

  def handle_event("save-form", params, socket) do
    {:noreply, assign(socket, :form_data, params)}
  end
end

defmodule PhoenixTest.WebApp.NestedLive do
  @moduledoc false

  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :form_data, %{})}
  end

  def render(assigns) do
    ~H"""
    {live_render(@socket, PhoenixTest.WebApp.ChildLive, id: "child-live-view")}

    <div id="parent-view-form-data">
      <%= for {key, value} <- @form_data do %>
        {key}: {value}
      <% end %>
    </div>
    """
  end
end
