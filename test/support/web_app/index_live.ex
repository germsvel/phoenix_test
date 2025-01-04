defmodule PhoenixTest.WebApp.IndexLive do
  @moduledoc false

  use Phoenix.LiveView

  def render(assigns) do
    ~H"""
    <h1 id="title" class="title" data-role="title">LiveView main page</h1>

    <.link navigate="/live/page_2?details=true&foo=bar">Navigate link</.link>
    <.link patch="/live/index?details=true&foo=bar">Patch link</.link>
    <.link href="/page/index?details=true&foo=bar">Navigate to non-liveview</.link>

    <.link class="multiple_links" href="/live/page_3">Multiple links</.link>
    <.link class="multiple_links" href="/live/page_4">Multiple links</.link>

    <.link navigate="/live/page_2?redirect_to=/live/index">Navigate (and redirect back) link</.link>

    <h2 :if={@details}>LiveView main page details</h2>

    <h3>{@h3}</h3>

    <button phx-click="change-h3">Change h3</button>

    <button phx-click="push-navigate">Button with push navigation</button>
    <button phx-click="push-patch">Button with push patch</button>

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

      <label>
        Comments <input type="text" name="comments" />
      </label>
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
          <option value={city}>{city}</option>
        <% end %>
      </select>
    </form>

    <div :if={@form_saved} id="form-data">
      <%= for {key, value} <- @form_data do %>
        {render_input_data(key, value)}
      <% end %>
    </div>

    <form id="no-phx-change-form" phx-submit="save-name">
      <label>
        Name <input name="name" />
      </label>
      <button type="submit">Save name</button>
    </form>

    <form id="owner-form" phx-submit="save-form">
      <label for="name">Name</label>
      <input id="name" name="name" />
    </form>

    <button form="owner-form" name="form-button" value="save-owner-form">
      Save Owner Form
    </button>

    <form id="nested-form" phx-submit="save-form">
      <label for="user-name">User Name</label>
      <input id="user-name" name="user[name]" />

      <label for="user-role">User Role</label>
      <input id="user-role" name="user[role]" value="El Jefe" />

      <label for="user-admin">User Admin</label>
      <select id="user-admin" name="user[admin]">
        <option value="true">True</option>
        <option value="false">False</option>
      </select>

      <input type="hidden" name="user[payer]" value="off" />
      <label for="user-payer">Payer</label>
      <input id="user-payer" type="checkbox" name="user[payer]" value="on" />

      <button type="submit" name="user[no-phx-change-form-button]" value="save">
        Save Nested Form
      </button>
    </form>

    <form id="full-form" phx-submit="save-form" phx-change="upload-change">
      <label for="first_name">First Name</label>
      <input id="first_name" name="first_name" />

      <label for="date">Date</label>
      <input type="date" id="date" name="date" />

      <input type="hidden" name="admin" value="off" />
      <label for="admin">Admin</label>
      <input id="admin" type="checkbox" name="admin" value="on" />

      <input type="hidden" name="subscribe?" value="off" />
      <label for="subscribe">Subscribe</label>
      <input id="subscribe" type="checkbox" name="subscribe?" value="on" />

      <label for="level">Level (number)</label>
      <input id="level" type="number" name="level" value="7" />

      <label for="race">Race</label>
      <select id="race" name="race">
        <option value="human">Human</option>
        <option value="elf">Elf</option>
        <option value="dwarf">Dwarf</option>
        <option value="orc">Orc</option>
        <option value="other_orc">Other Orc</option>
      </select>

      <label for="race_2">Race 2</label>
      <select multiple id="race_2" name="race_2[]">
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
      Prefilled notes
      </textarea>

      <label for="disabled_textarea">Disabled textaread</label>
      <textarea id="disabled_textarea" name="disabled_textarea" rows="5" cols="33" disabled>
      Prefilled content
      </textarea>

      <label>
        Disabled select
        <select disabled name="disabled_select">
          <option value="">Select...</option>
        </select>
      </label>

      <label for={@uploads.avatar.ref}>Avatar</label>
      <.live_file_input upload={@uploads.avatar} />

      <button type="submit" name="full_form_button" value="save">Save Full Form</button>
    </form>

    <form id="redirect-form" phx-submit="save-redirect-form">
      <label for="redirect-form-name">Name</label>
      <input id="redirect-form-name" name="name" />
      <button type="submit" id="redirect-form-submit">
        Save Redirect Form
      </button>
    </form>

    <form id="live-redirect-form" phx-change="change-redirect-form">
      <label for="live-redirect-form-name">Name</label>
      <select id="live-redirect-form-name" name="name">
        <option value="1">One</option>
        <option value="2">Two</option>
      </select>
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

      <label for="no-name-attribute">No Name Attribute</label>
      <input id="no-name-attribute" />

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

    <form id="redirect-on-change" phx-change="redirect-on-change">
      <label for="email-on-change">Email with redirect</label>
      <input id="email-on-change" name="email" />
    </form>

    <form id="complex-labels" phx-change="change-form" phx-submit="save-form">
      <label for="complex-name">
        Name <span>*</span>
      </label>
      <input id="complex-name" name="name" />

      <label for="complex-human">
        Human <span>*</span>
      </label>
      <input type="hidden" name="human" value="no" />
      <input type="checkbox" id="complex-human" name="human" value="yes" />

      <label for="complex-animals">Choose a pet: <span>*</span></label>
      <select id="complex-animals" name="pet">
        <option value="dog">Dog</option>
        <option value="cat">Cat</option>
      </select>

      <fieldset>
        <legend>Book or movie?</legend>

        <input type="radio" id="complex-book" name="book-or-movie" value="book" />
        <label for="complex-book">Book <span>*</span></label>

        <input type="radio" id="complex-movie" name="book-or-movie" value="movie" />
        <label for="complex-movie">Movie <span>*</span></label>
      </fieldset>

      <label for={@uploads.avatar.ref}>Avatar <span>*</span></label>
      <.live_file_input upload={@uploads.avatar} />

      <button type="submit">Save</button>
    </form>

    <form id="same-labels" phx-submit="save-form" phx-change="change-form">
      <fieldset name="like-elixir">
        <legend>Do you like Elixir:</legend>

        <div>
          <input name="elixir-yes" type="radio" id="elixir-yes" value="yes" />
          <label for="elixir-yes">Yes</label>
        </div>
        <div>
          <input name="elixir-no" type="radio" id="elixir-no" value="no" />
          <label for="elixir-no">No</label>
        </div>
      </fieldset>

      <fieldset>
        <legend>Do you like Erlang:</legend>

        <div>
          <input name="erlang-yes" type="radio" id="erlang-yes" value="yes" />
          <label for="erlang-yes">Yes</label>
        </div>
        <div>
          <input name="erlang-yes" type="radio" id="erlang-no" value="no" />
          <label for="erlang-no">No</label>
        </div>
      </fieldset>

      <fieldset>
        <legend>Favorite characters?</legend>
        <div>Book</div>
        <label for="book-characters">Character</label>
        <input type="text" name="book-characters" id="book-characters" />

        <div>Movies</div>
        <label for="movie-characters">Character</label>
        <input type="text" name="movie-characters" id="movie-characters" />
      </fieldset>

      <fieldset>
        <legend>Do you like Elixir?</legend>
        <label for="like-elixir">Yes</label>
        <input type="hidden" name="like-elixir" value="no" />
        <input type="checkbox" name="like-elixir" id="like-elixir" value="yes" />

        <legend>Do you like Erlang</legend>
        <label for="like-erlang">Yes</label>
        <input type="hidden" name="like-erlang" value="no" />
        <input type="checkbox" name="like-erlang" id="like-erlang" value="yes" />
      </fieldset>

      <fieldset>
        <legend>Select your favorite character</legend>

        <label for="select-favorite-character">Character</label>
        <select id="select-favorite-character" name="favorite-character">
          <option value="Frodo">Frodo</option>
          <option value="Sam">Sam</option>
          <option value="Pippin">Pippin</option>
          <option value="Merry">Merry</option>
        </select>
      </fieldset>

      <fieldset>
        <label for="select-least-favorite-character">Character</label>
        <select id="select-least-favorite-character" name="least-favorite-character">
          <option value="Frodo">Frodo</option>
          <option value="Sam">Sam</option>
          <option value="Pippin">Pippin</option>
          <option value="Merry">Merry</option>
        </select>
      </fieldset>

      <fieldset>
        <legend>Upload your avatars</legend>

        <label for={@uploads.main_avatar.ref}>Avatar</label>
        <.live_file_input upload={@uploads.main_avatar} />

        <label for={@uploads.backup_avatar.ref}>Avatar</label>
        <.live_file_input upload={@uploads.backup_avatar} />
      </fieldset>

      <button type="submit">
        Submit Form
      </button>
    </form>

    <form id="changes-hidden-input-form" phx-change="set-hidden-race">
      <input type="hidden" name="hidden_race" value={@hidden_input_race} />

      <label>Email for hidden <input type="email" name="email" /></label>
      <label>Name for hidden <input type="name" name="name" /></label>
    </form>

    <div id="not-a-form">
      <fieldset>
        <legend>Select a maintenance drone:</legend>

        <div>
          <input phx-click="select-drone" type="radio" id="huey" name="drone" value="huey" checked />
          <label for="huey">Huey</label>
        </div>

        <div>
          <input phx-click="select-drone" type="radio" id="dewey" name="drone" value="dewey" />
          <label for="dewey">Dewey</label>
        </div>

        <div>
          <input phx-click="select-drone" type="radio" id="louie" name="drone" value="louie" />
          <label for="louie">Louie</label>
        </div>
      </fieldset>

      <label for="pet-select">Choose a pet:</label>
      <select multiple name="pets" id="pet-select">
        <option phx-click="select-pet" value="dog">Dog</option>
        <option phx-click="select-pet" value="cat">Cat</option>
      </select>

      <fieldset>
        <legend>Select to get second breakfast:</legend>

        <div>
          <input
            phx-click="toggle-second-breakfast"
            type="checkbox"
            id="second-breakfast"
            name="second-breakfast"
            value="second-breakfast"
          />
          <label for="second-breakfast">Second Breakfast</label>
        </div>
      </fieldset>
    </div>

    <label for="no-form-no-phx-click">Invalid Radio Button</label>
    <input type="radio" id="no-form-no-phx-click" name="invalids" value="nothing" checked />

    <label for="no-form-no-phx-click-select">Invalid Select Option</label>
    <select name="pets" id="no-form-no-phx-click-select">
      <option value="dog">Dog</option>
    </select>

    <label for="no-form-no-phx-click-checkbox">Invalid Checkbox</label>
    <input type="checkbox" id="no-form-no-phx-click-checkbox" name="no-breakfast" />

    <div id="hook" phx-hook="SomeHook"></div>
    <div id="hook-with-redirect" phx-hook="SomeOtherHook"></div>

    <form
      id="trigger-form"
      phx-submit="trigger-form"
      phx-trigger-action={@trigger_submit}
      action="/page/create_record"
      method="post"
    >
      <input type="hidden" name="trigger_action_hidden_input" value="trigger_action_hidden_value" />
      <label>Trigger action <input type="text" name="trigger_action_input" /></label>
    </form>

    <button phx-click="trigger-form">Trigger from elsewhere</button>

    <form
      id="trigger-multiple-form-1"
      phx-submit="trigger-form"
      phx-trigger-action={@trigger_multiple_submit}
    />

    <form
      id="trigger-multiple-form-2"
      phx-submit="trigger-form"
      phx-trigger-action={@trigger_multiple_submit}
    />

    <button phx-click="trigger-multiple-forms">Trigger multiple</button>

    <form
      id="redirect-and-trigger-form"
      phx-change="patch-and-trigger-form"
      phx-trigger-action={@redirect_and_trigger_submit}
      action="/page/create_record"
      method="post"
    >
      <label>
        Patch and trigger action <input type="text" name="patch_and_trigger_action" />
      </label>
      <button phx-click="redirect-and-trigger-form">Redirect and trigger action</button>
      <button phx-click="navigate-and-trigger-form">Navigate and trigger action</button>
    </form>

    <form id="upload-change-form" phx-change="upload-change">
      <label for={@uploads.avatar.ref}>Avatar</label>
      <.live_file_input upload={@uploads.avatar} />
    </form>

    <div :if={@upload_change_triggered} id="upload-change-result">phx-change triggered on file selection</div>

    <form id="upload-redirect-form" phx-change="upload-change">
      <label for={@uploads.redirect_avatar.ref}>Redirect Avatar</label>
      <.live_file_input upload={@uploads.redirect_avatar} />
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
      |> assign(:h3, "this is an h3")
      |> assign(:details, false)
      |> assign(:show_tab, false)
      |> assign(:form_saved, false)
      |> assign(:form_data, %{})
      |> assign(:show_form_errors, false)
      |> assign(:cities, [])
      |> assign(:hidden_input_race, "human")
      |> assign(:trigger_submit, false)
      |> assign(:trigger_multiple_submit, false)
      |> assign(:redirect_and_trigger_submit, false)
      |> assign(:upload_change_triggered, false)
      |> allow_upload(:avatar, accept: ~w(.jpg .jpeg))
      |> allow_upload(:main_avatar, accept: ~w(.jpg .jpeg))
      |> allow_upload(:backup_avatar, accept: ~w(.jpg .jpeg))
      |> allow_upload(:redirect_avatar, accept: ~w(.jpg .jpeg), progress: &handle_progress/3)
    }
  end

  defp handle_progress(:redirect_avatar, entry, socket) do
    if entry.done? do
      {:noreply, push_navigate(socket, to: "/live/page_2", replace: true)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("change-h3", _, socket) do
    {:noreply, assign(socket, :h3, "I've been changed!")}
  end

  def handle_event("change-page-title", _, socket) do
    {:noreply, assign(socket, :page_title, "Title changed!")}
  end

  def handle_event("show-tab", _, socket) do
    {:noreply, assign(socket, :show_tab, true)}
  end

  def handle_event("change-form", form_data, socket) do
   {
      :noreply,
      socket
      |> assign(:form_saved, true)
      |> assign(:form_data, form_data)
    }
  end

  def handle_event("save-form", form_data, socket) do
    avatars =
      consume_uploaded_entries(socket, :avatar, fn _, %{client_name: name} ->
        {:ok, name}
      end)

    main_avatars =
      consume_uploaded_entries(socket, :main_avatar, fn _, %{client_name: name} -> {:ok, name} end)

    form_data =
      form_data
      |> Map.put("avatar", List.first(avatars))
      |> Map.put("main_avatar", List.first(main_avatars))

    {
      :noreply,
      socket
      |> assign(:form_saved, true)
      |> assign(:form_data, form_data)
    }
  end

  def handle_event("trigger-form", _form_data, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end

  def handle_event("trigger-multiple-forms", _form_data, socket) do
    {:noreply, assign(socket, :trigger_multiple_submit, true)}
  end

  def handle_event("patch-and-trigger-form", _form_data, socket) do
    {:noreply,
     socket
     |> assign(:redirect_and_trigger_submit, true)
     |> push_patch(to: "/live/index/alias")}
  end

  def handle_event("redirect-and-trigger-form", _form_data, socket) do
    {:noreply,
     socket
     |> redirect(to: "/live/page_2")
     |> assign(:redirect_and_trigger_submit, true)}
  end

  def handle_event("navigate-and-trigger-form", _form_data, socket) do
    {:noreply,
     socket
     |> push_navigate(to: "/live/page_2")
     |> assign(:redirect_and_trigger_submit, true)}
  end

  def handle_event("set-hidden-race", form_data, socket) do
    race =
      case form_data["name"] do
        "Frodo" -> "hobbit"
        _ -> "human"
      end

    {
      :noreply,
      socket
      |> assign(:form_saved, true)
      |> assign(:form_data, form_data)
      |> assign(:hidden_input_race, race)
    }
  end

  def handle_event("save-redirect-form", _, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Form saved and redirected")
     |> push_navigate(to: "/live/page_2")}
  end

  def handle_event("change-redirect-form", _, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Redirected on phx-change")
     |> push_navigate(to: "/auth/live/page_2")}
  end

  def handle_event("save-redirect-form-to-static", _, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Redirected to static page")
     |> redirect(to: "/page/index")}
  end

  def handle_event("reset-email-form", _, socket) do
    socket
    |> assign(:email, nil)
    |> then(&{:noreply, &1})
  end

  def handle_event("validate-email", %{"email" => email} = params, socket) do
    case email do
      empty when empty == nil or empty == "" ->
        {:noreply, assign(socket, :show_form_errors, true)}

      _valid ->
        socket
        |> assign(:email, email)
        |> assign(:form_saved, true)
        |> assign(:form_data, params)
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

  def handle_event("select-pet", %{"value" => value}, socket) do
    form_data =
      case socket.assigns.form_data do
        %{selected: values} -> %{selected: values ++ [value]}
        %{} -> %{selected: [value]}
      end

    socket
    |> assign(:form_saved, true)
    |> assign(:form_data, form_data)
    |> then(&{:noreply, &1})
  end

  def handle_event("toggle-second-breakfast", params, socket) do
    socket
    |> assign(:form_saved, true)
    |> assign(:form_data, params)
    |> then(&{:noreply, &1})
  end

  def handle_event("redirect-on-change", _, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Redirected on phx-change")
     |> push_navigate(to: "/live/page_2")}
  end

  def handle_event("push-navigate", _, socket) do
    {:noreply, push_navigate(socket, to: "/live/page_2?foo=bar")}
  end

  def handle_event("push-patch", _, socket) do
    {:noreply, push_patch(socket, to: "/live/index?foo=bar")}
  end

  def handle_event("hook_event", params, socket) do
    {
      :noreply,
      socket
      |> assign(:form_saved, true)
      |> assign(:form_data, params)
    }
  end

  def handle_event("hook_with_redirect_event", _params, socket) do
    {:noreply, push_navigate(socket, to: "/live/page_2")}
  end

  def handle_event("select-drone", params, socket) do
    {
      :noreply,
      socket
      |> assign(:form_saved, true)
      |> assign(:form_data, params)
    }
  end

  def handle_event("upload-change", _params, socket) do
    {
      :noreply,
      socket
      |> assign(:upload_change_triggered, true)
    }
  end

  defp render_input_data(key, value) when value == "" or is_nil(value) do
    "#{key}'s value is empty"
  end

  defp render_input_data(key, value) when is_binary(value) do
    "#{key}: #{value}"
  end

  defp render_input_data(key, values) when is_list(values) do
    "#{key}: [#{Enum.map_join(values, ", ", & &1)}]"
  end

  defp render_input_data(key, values) do
    Enum.map_join(values, "\n", fn {nested_key, value} ->
      render_input_data("#{key}:#{nested_key}", value)
    end)
  end
end
