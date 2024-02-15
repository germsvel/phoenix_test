defmodule PhoenixTest.IndexLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~H"""
    <h1 id="title" class="title" data-role="title">LiveView main page</h1>

    <.link navigate="/live/page_2">Navigate link</.link>
    <.link patch="/live/index?details=true">Patch link</.link>
    <.link href="/page/index">Navigate to non-liveview</.link>

    <.link class="multiple_links" href="/live/page_3">Multiple links</.link>
    <.link class="multiple_links" href="/live/page_4">Multiple links</.link>

    <h2 :if={@details}>LiveView main page details</h2>

    <button phx-click="change-page-title">Change page title</button>

    <button phx-click="show-tab">Show tab</button>

    <div :if={@show_tab} id="tab">
      <h2>Tab title</h2>
    </div>

    <div :if={@show_form_errors} id="form-errors">
      Errors present
    </div>

    <form id="email-form" phx-change="validate-email" phx-submit="save-form">
      <input name="email" />
      <button type="submit">Save email</button>
    </form>

    <div :if={@form_saved} id="form-data">
      <%= for {key, value} <- @form_data do %>
        <%= render_input_data(key, value) %>
      <% end %>
    </div>

    <form id="no-phx-change-form" phx-submit="save-name">
      <input name="name" />
      <button type="submit">Save name</button>
    </form>

    <form id="nested-form" phx-submit="save-form">
      <input name="user[name]" />
      <button type="submit">Save</button>
    </form>

    <form id="full-form" phx-submit="save-form">
      <label for="name">Name</label>
      <input name="name" />

      <label for="admin">Admin</label>
      <input type="checkbox" name="admin" value="on" />

      <label for="race">Race</label>
      <select name="race">
        <option value="human">Human</option>
        <option value="elf">Elf</option>
        <option value="dwarf">Dwarf</option>
        <option value="orc">Orc</option>
      </select>

      <label for="notes">Notes</label>
      <textarea name="notes" rows="5" cols="33">
      </textarea>
    </form>

    <form id="redirect-form" phx-submit="save-redirect-form">
      <label for="name">Name</label>
      <input name="name" />
      <button type="submit" id="redirect-form-submit">
        Save
      </button>
    </form>

    <form id="redirect-form-to-static" phx-submit="save-redirect-form-to-static">
      <label for="name">Name</label>
      <input name="name" />
      <button type="submit" id="redirect-form-to-static-submit">
        Save
      </button>
    </form>

    <form id="invalid-form">
      <label for="name">Name</label>
      <input name="name" />
      <button type="submit">
        Submit Invalid Form
      </button>
    </form>

    <form id="non-liveview-form" action="/page/redirect_to_static" method="post">
      <label for="name">Name</label>
      <input name="name" />
      <button type="submit">
        Submit Non LiveView
      </button>
    </form>
    """
  end

  def handle_params(%{"details" => "true"}, _uri, socket) do
    {:noreply, assign(socket, :details, true)}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  def mount(_params, _session, socket) do
    {
      :ok,
      socket
      |> assign(:details, false)
      |> assign(:show_tab, false)
      |> assign(:form_saved, false)
      |> assign(:form_data, %{})
      |> assign(:show_form_errors, false)
    }
  end

  def handle_event("change-page-title", _, socket) do
    {:noreply, assign(socket, :page_title, "Title changed!")}
  end

  def handle_event("show-tab", _, socket) do
    {:noreply, assign(socket, :show_tab, true)}
  end

  def handle_event("save-form", form_data, socket) do
    {
      :noreply,
      socket
      |> assign(:form_saved, true)
      |> assign(:form_data, form_data)
    }
  end

  def handle_event("save-redirect-form", _, socket) do
    {:noreply, push_navigate(socket, to: "/live/page_2")}
  end

  def handle_event("save-redirect-form-to-static", _, socket) do
    {:noreply, redirect(socket, to: "/page/index")}
  end

  def handle_event("validate-email", %{"email" => email}, socket) do
    case email do
      empty when empty == nil or empty == "" ->
        {:noreply, assign(socket, :show_form_errors, true)}

      _valid ->
        {:noreply, socket}
    end
  end

  defp render_input_data(key, value) when is_binary(value) do
    "#{key}: #{value}"
  end

  defp render_input_data(key, values) do
    Enum.map_join(values, "\n", fn {nested_key, value} ->
      render_input_data("#{key}:#{nested_key}", value)
    end)
  end
end
