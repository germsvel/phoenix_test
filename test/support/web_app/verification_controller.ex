defmodule PhoenixTest.WebApp.VerificationController do
  @moduledoc false
  use Phoenix.Controller, formats: [:html]

  def form(conn, %{"run_id" => run_id}) do
    token = Phoenix.Controller.get_csrf_token()

    html(conn, """
    <!doctype html>
    <html lang="en">
      <body>
        <form id="verification-form" action="/verify/#{run_id}/static" method="post">
          <input type="hidden" name="_csrf_token" value="#{token}">
          <label for="verification-name">Name</label>
          <input id="verification-name" name="person[name]" value="Original">
          <button type="submit" name="person[action]" value="save">Save</button>
        </form>
        <form id="verification-checkbox-form" action="/verify/#{run_id}/static" method="post">
          <input type="hidden" name="_csrf_token" value="#{token}">
          <input type="hidden" name="person[enabled]" value="false">
          <label for="verification-enabled">Enabled</label>
          <input id="verification-enabled" type="checkbox" name="person[enabled]" value="true">
          <button type="submit">Save Preference</button>
        </form>
        <form id="verification-roles-form" action="/verify/#{run_id}/static" method="post">
          <input type="hidden" name="_csrf_token" value="#{token}">
          <label for="verification-roles">Roles</label>
          <select id="verification-roles" name="person[roles][]" multiple>
            <option value="admin">Admin</option>
            <option value="reviewer">Reviewer</option>
            <option value="viewer">Viewer</option>
          </select>
          <button type="submit">Save Roles</button>
        </form>
      </body>
    </html>
    """)
  end

  def submit(conn, _params), do: html(conn, "Saved")
end
