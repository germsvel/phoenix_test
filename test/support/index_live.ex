defmodule PhoenixTest.IndexLive do
  @moduledoc false
  use Phoenix.LiveView

  def render(assigns) do
    ~H"""
    <h1 id="title" class="title" data-role="title">LiveView main page</h1>

    <.link navigate="/live/page_2">Navigate link</.link>
    <.link patch="/live/index?details=true&foo=bar">Patch link</.link>
    <.link href="/page/index">Navigate to non-liveview</.link>

    <.link class="multiple_links" href="/live/page_3">Multiple links</.link>
    <.link class="multiple_links" href="/live/page_4">Multiple links</.link>

    <.link navigate="/live/page_2?redirect_to=/live/index">Navigate (and redirect back) link</.link>

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
      <label for="email">Email</label>
      <input id="email" name="email" value={assigns[:email]} />
      <button>Save Email</button>
    </form>
    <button phx-click="reset-email-form">Reset</button>

    <form id="pre-rendered-data-form" phx-change="save-form" phx-submit="save-form">
      <label>
        Pre Rendered Input <input name="input" value="value" />
      </label>

      <select name="select">
        <option value="not_selected">Not selected</option>
        <option value="selected" selected>Selected</option>
      </select>

      <select name="select_none_selected">
        <option value="first">Selected by default</option>
      </select>

      <input name="checkbox" type="checkbox" value="not_checked" />
      <input name="checkbox" type="checkbox" value="checked" checked />

      <input name="radio" type="radio" value="not_checked" />
      <input name="radio" type="radio" value="checked" checked />
    </form>

    <form id="country-form" phx-change="select-country">
      <label for="country">Country</label>
      <select id="country" name="country">
        <option value="Bolivia">Bolivia</option>
        <option value="Chile">Chile</option>
        <option value="Argentina">Argentina</option>
        <option value="Paraguay">Paraguay</option>
      </select>
    </form>

    <form id="city-form" phx-change="select-city">
      <label for="city">City</label>
      <select id="city" name="city">
        <%= for city <- @cities do %>
          <option value={city}><%= city %></option>
        <% end %>
      </select>
    </form>

    <div :if={@form_saved} id="form-data">
      <%= for {key, value} <- @form_data do %>
        <%= render_input_data(key, value) %>
      <% end %>
    </div>

    <form id="no-phx-change-form" phx-submit="save-name">
      <label>
        Name <input name="name" />
      </label>
      <button type="submit">Save name</button>
    </form>

    <form id="nested-form" phx-submit="save-form">
      <label for="user-name">User Name</label>
      <input id="user-name" name="user[name]" />

      <label for="user-admin">User Admin</label>
      <select id="user-admin" name="user[admin]">
        <option value="true">True</option>
        <option value="false">False</option>
      </select>

      <button type="submit" name="no-phx-change-form-button" value="save">
        Save Nested Form
      </button>
    </form>

    <form id="full-form" phx-submit="save-form">
      <label for="first_name">First Name</label>
      <input id="first_name" name="first_name" />

      <label for="date">Date</label>
      <input type="date" id="date" name="date" />

      <input type="hidden" name="admin" value="off" />
      <label for="admin">Admin</label>
      <input id="admin" type="checkbox" name="admin" value="on" />

      <label for="race">Race</label>
      <select id="race" name="race">
        <option value="human">Human</option>
        <option value="elf">Elf</option>
        <option value="dwarf">Dwarf</option>
        <option value="orc">Orc</option>
      </select>

      <fieldset>
        <legend>Please select your preferred contact method:</legend>
        <div>
          <input type="radio" id="email_choice" name="contact" value="email" />
          <label for="email_choice">Email Choice</label>
          <input type="radio" id="phone_choice" name="contact" value="phone" />
          <label for="phone_choice">Phone Choice</label>
          <input type="radio" id="mail_choice" name="contact" value="mail" checked />
          <label for="mail_choice">Mail Choice</label>
        </div>
      </fieldset>

      <label for="notes">Notes</label>
      <textarea id="notes" name="notes" rows="5" cols="33">
      </textarea>

      <button type="submit" name="full_form_button" value="save">Save Full Form</button>
    </form>

    <form id="redirect-form" phx-submit="save-redirect-form">
      <label for="redirect-form-name">Name</label>
      <input id="redirect-form-name" name="name" />
      <button type="submit" id="redirect-form-submit">
        Save Redirect Form
      </button>
    </form>

    <form id="redirect-form-to-static" phx-submit="save-redirect-form-to-static">
      <label for="redirect-to-static-name">Name</label>
      <input id="redirect-to-static-name" name="name" />
      <button type="submit" id="redirect-form-to-static-submit">
        Save Redirect to Static Form
      </button>
    </form>

    <form id="invalid-form">
      <label for="invalid-form-email">Email (no input)</label>

      <label for="invalid-form-name">Name</label>
      <input id="invalid-form-name" name="name" />
      <button type="submit">
        Submit Invalid Form
      </button>
    </form>

    <form id="non-liveview-form" action="/page/create_record" method="post">
      <label for="non-liveview-form-name">Name</label>
      <input id="non-liveview-form-name" name="name" />
      <button type="submit" name="button" value="save">
        Submit Non LiveView
      </button>
    </form>

    <form id="pre-rendered-data-non-liveview-form" action="/page/create_record" method="post">
      <input name="input" value="value" />

      <select name="select">
        <option value="not_selected">Not selected</option>
        <option value="selected" selected>Selected</option>
      </select>

      <select name="select_none_selected">
        <option value="first">Selected by default</option>
      </select>

      <input name="checkbox" type="checkbox" value="not_checked" />
      <input name="checkbox" type="checkbox" value="checked" checked />

      <input name="radio" type="radio" value="not_checked" />
      <input name="radio" type="radio" value="checked" checked />
    </form>

    <form id="button-less-form" phx-submit="save-form">
      <label for="country-of-origin">Country of Origin</label>
      <input id="country-of-origin" name="country" />
    </form>

    <button type="button">Actionless Button</button>
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
      |> assign(:cities, [])
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

  def handle_event("reset-email-form", _, socket) do
    socket
    |> assign(:email, nil)
    |> then(&{:noreply, &1})
  end

  def handle_event("validate-email", %{"email" => email}, socket) do
    case email do
      empty when empty == nil or empty == "" ->
        {:noreply, assign(socket, :show_form_errors, true)}

      _valid ->
        socket
        |> assign(:email, email)
        |> then(&{:noreply, &1})
    end
  end

  def handle_event("select-country", %{"country" => country}, socket) do
    case country do
      "Bolivia" ->
        socket
        |> assign(:country, country)
        |> assign(:cities, ["Santa Cruz", "La Paz", "Cochabamba", "Other"])
        |> then(&{:noreply, &1})
    end
  end

  def handle_event("select-city", %{"city" => city}, socket) do
    form_data = %{socket.assigns[:country] => city}

    socket
    |> assign(:form_saved, true)
    |> assign(:form_data, form_data)
    |> then(&{:noreply, &1})
  end

  defp render_input_data(key, value) when value == "" or is_nil(value) do
    "#{key}'s value is empty"
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
