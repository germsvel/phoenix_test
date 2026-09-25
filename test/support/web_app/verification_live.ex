defmodule PhoenixTest.WebApp.VerificationLive do
  @moduledoc false
  use Phoenix.LiveView

  alias Phoenix.LiveView.JS

  def mount(%{"run_id" => run_id} = params, _session, socket) do
    socket =
      socket
      |> assign(
        run_id: run_id,
        submitted: false,
        change_count: 0,
        change_person: %{"name" => "Original", "role" => "reader", "enabled" => "false"},
        show_stale: true,
        show_added: false,
        tab: Map.get(params, "tab", "home")
      )
      |> allow_upload(:photos, accept: ~w(.jpg .png), max_entries: 2)

    {:ok, socket}
  end

  def handle_params(params, _uri, socket) do
    {:noreply, assign(socket, tab: Map.get(params, "tab", "home"))}
  end

  def render(assigns) do
    ~H"""
    <form id="verification-form" phx-submit="save">
      <label for="verification-name">Name</label>
      <input id="verification-name" name="person[name]" value="Original" />
      <button type="submit" name="person[action]" value="save">Save</button>
    </form>
    <form id="verification-checkbox-form" phx-submit="save">
      <input type="hidden" name="person[enabled]" value="false" />
      <label for="verification-enabled">Enabled</label>
      <input id="verification-enabled" type="checkbox" name="person[enabled]" value="true" />
      <button type="submit">Save Preference</button>
    </form>
    <form id="verification-roles-form" phx-submit="save">
      <label for="verification-roles">Roles</label>
      <select id="verification-roles" name="person[roles][]" multiple>
        <option value="admin">Admin</option>
        <option value="reviewer">Reviewer</option>
        <option value="viewer">Viewer</option>
      </select>
      <button type="submit">Save Roles</button>
    </form>
    <form id="verification-nested-form" phx-submit="save">
      <input name="profile[tags][]" value="alpha" />
      <input name="profile[contacts][0][name]" value="Ada" />
      <input name="profile[contacts][0][role]" value="admin" />
      <input name="profile[tags][]" value="beta" />
      <input name="profile[contacts][1][name]" value="Lin" />
      <input name="profile[contacts][1][role]" value="editor" />
      <input name="profile[settings][theme]" value="dark" />
      <input name="duplicate" value="first" />
      <input name="duplicate" value="second" />
      <button type="submit">Save Nested Data</button>
    </form>
    <form id="verification-defaults-form" phx-submit="save">
      <label><input type="radio" name="person[choice]" value="ignored" /> Ignored choice</label>
      <label>
        <input type="radio" name="person[choice]" value="selected" checked /> Selected choice
      </label>
      <label>
        <input type="checkbox" name="person[standalone]" value="yes" /> Standalone checkbox
      </label>
      <label for="verification-default-roles">Default roles</label>
      <select id="verification-default-roles" name="person[roles][]" multiple>
        <option value="admin">Admin</option>
        <option value="reader">Reader</option>
      </select>
      <label for="verification-default-text">Default text</label>
      <input id="verification-default-text" name="person[default_text]" value="Original" />
      <label for="verification-default-choice">Default choice</label>
      <select id="verification-default-choice" name="person[default_choice]">
        <option value="first">First</option>
        <option value="second">Second</option>
      </select>
      <button type="submit">Save Defaults</button>
    </form>
    <form id="verification-disabled-readonly-form" phx-submit="save">
      <label for="verification-active">Active</label>
      <input id="verification-active" name="person[active]" value="included" />
      <label for="verification-disabled-text">Disabled text</label>
      <input id="verification-disabled-text" name="person[disabled_text]" value="excluded" disabled />
      <label for="verification-disabled-notes">Disabled notes</label>
      <textarea id="verification-disabled-notes" name="person[disabled_notes]" disabled>excluded notes</textarea>
      <label for="verification-disabled-choice">Disabled choice</label>
      <select id="verification-disabled-choice" name="person[disabled_choice]" disabled>
        <option value="excluded" selected>Excluded</option>
      </select>
      <label for="verification-disabled-check">Disabled check</label>
      <input
        id="verification-disabled-check"
        type="checkbox"
        name="person[disabled_check]"
        value="excluded"
        checked
        disabled
      />
      <label for="verification-readonly-text">Readonly text</label>
      <input id="verification-readonly-text" name="person[readonly_text]" value="locked" readonly />
      <label for="verification-readonly-notes">Readonly notes</label>
      <textarea id="verification-readonly-notes" name="person[readonly_notes]" readonly>locked notes</textarea>
      <button type="submit">Save Controls</button>
    </form>
    <form id="verification-change-form" phx-change="validate" phx-submit="save">
      <label for="verification-change-name">Change name</label>
      <input id="verification-change-name" name="person[name]" value={@change_person["name"]} />
      <label for="verification-change-role">Change role</label>
      <select id="verification-change-role" name="person[role]">
        <option value="reader" selected={@change_person["role"] == "reader"}>Reader</option>
        <option value="admin" selected={@change_person["role"] == "admin"}>Admin</option>
      </select>
      <input type="hidden" name="person[enabled]" value="false" />
      <label for="verification-change-enabled">Change enabled</label>
      <input
        id="verification-change-enabled"
        type="checkbox"
        name="person[enabled]"
        value="true"
        checked={@change_person["enabled"] == "true"}
      />
    </form>
    <p id="verification-change-count">{@change_count}</p>
    <form id="verification-submitter-form" phx-submit="save">
      <label for="verification-submitter-name">Submitter name</label>
      <input id="verification-submitter-name" name="person[name]" value="Original" />
      <button type="submit" name="person[action]" value="first">First Action</button>
      <button type="submit" name="person[action]" value="second">Second Action</button>
      <button type="submit">Unnamed Action</button>
    </form>
    <button type="submit" form="verification-submitter-form" name="person[action]" value="external">
      External Action
    </button>
    <form id="verification-upload-form" phx-change="upload_change" phx-submit="upload_save">
      <label for={@uploads.photos.ref}>Photos</label>
      <.live_file_input upload={@uploads.photos} />
      <button type="submit">Save Photos</button>
    </form>
    <form id="verification-dynamic-form" phx-submit="save">
      <div id="verification-dynamic-kept-wrapper" phx-update="ignore">
        <label for="verification-dynamic-kept">Kept field</label>
        <input id="verification-dynamic-kept" name="person[kept]" value="Initial" />
      </div>
      <label :if={@show_stale} for="verification-dynamic-stale">Stale field</label>
      <input :if={@show_stale} id="verification-dynamic-stale" name="person[stale]" value="old" />
      <label :if={@show_added} for="verification-dynamic-added">Added field</label>
      <input :if={@show_added} id="verification-dynamic-added" name="person[added]" />
      <button type="submit">Save Dynamic</button>
    </form>
    <button type="button" phx-click="remove_stale">Remove Stale</button>
    <button type="button" phx-click="add_field">Add Field</button>
    <button type="button" phx-click="verify_click" phx-value-id="42" phx-value-origin="button">
      Record Click
    </button>
    <button type="button" phx-click={JS.push("verify_push", value: %{id: "77", origin: "js"})}>
      Push Event
    </button>
    <.link patch={"/verify/#{@run_id}/live?tab=details"}>Patch Verify</.link>
    <.link navigate={"/verify/#{@run_id}/live/destination"}>Navigate Verify</.link>
    <button type="button" phx-click="verify_redirect">Redirect Verify</button>
    <p id="verification-tab">{@tab}</p>
    <p :if={@submitted} id="verification-done">Saved</p>
    """
  end

  def handle_event("verify_click", _params, socket), do: {:noreply, assign(socket, submitted: true)}
  def handle_event("verify_push", _params, socket), do: {:noreply, assign(socket, submitted: true)}

  def handle_event("verify_redirect", _params, socket) do
    {:noreply, redirect(socket, to: "/verify/#{socket.assigns.run_id}/static")}
  end

  def handle_event("upload_change", _params, socket), do: {:noreply, socket}

  def handle_event("upload_save", _params, socket) do
    consume_uploaded_entries(socket, :photos, fn _meta, entry -> {:ok, entry.client_name} end)
    {:noreply, assign(socket, submitted: true)}
  end

  def handle_event("remove_stale", _params, socket) do
    {:noreply, assign(socket, show_stale: false)}
  end

  def handle_event("add_field", _params, socket) do
    {:noreply, assign(socket, show_added: true)}
  end

  def handle_event("validate", %{"person" => person}, socket) do
    {:noreply,
     socket
     |> assign(:change_person, person)
     |> update(:change_count, &(&1 + 1))}
  end

  def handle_event("save", _params, socket) do
    {:noreply, assign(socket, submitted: true)}
  end
end
