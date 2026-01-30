defmodule PhoenixTest.WebApp.ConditionalFormLive do
  @moduledoc false

  use Phoenix.LiveView

  def render(assigns) do
    ~H"""
    <h1>Conditional Form Test</h1>

    <form id="conditional-form" phx-change="change-form" phx-submit="save-form">
      <label for="version">Version</label>
      <select id="version" name="version">
        <option value="a">Version A</option>
        <option value="b">Version B</option>
      </select>

      <label :if={@version == "a"} for="version_a_text">Version A Text</label>
      <input :if={@version == "a"} id="version_a_text" name="version_a_text" value={@form_data["version_a_text"]} />

      <label :if={@version == "b"} for="version_b_text">Version B Text</label>
      <input :if={@version == "b"} id="version_b_text" name="version_b_text" value={@form_data["version_b_text"]} />

      <button type="submit">Save</button>
    </form>

    <div :if={@form_saved} id="form-data">
      <%= for {key, value} <- @submitted_data do %>
        <span>{key}: {value}</span>
      <% end %>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       version: "a",
       form_data: %{},
       form_saved: false,
       submitted_data: %{}
     )}
  end

  def handle_event("change-form", form_data, socket) do
    {:noreply,
     assign(socket,
       version: form_data["version"] || socket.assigns.version,
       form_data: form_data
     )}
  end

  def handle_event("save-form", form_data, socket) do
    {:noreply,
     assign(socket,
       form_saved: true,
       submitted_data: form_data
     )}
  end
end
