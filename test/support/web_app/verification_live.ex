defmodule PhoenixTest.WebApp.VerificationLive do
  @moduledoc false
  use Phoenix.LiveView

  def mount(%{"run_id" => run_id}, _session, socket) do
    {:ok, assign(socket, run_id: run_id, submitted: false)}
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
    <p :if={@submitted} id="verification-done">Saved</p>
    """
  end

  def handle_event("save", _params, socket) do
    {:noreply, assign(socket, submitted: true)}
  end
end
