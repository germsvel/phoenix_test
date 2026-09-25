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
        <form id="verification-get-form" action="/verify/#{run_id}/static/get?seed=from-action&amp;shared=old" method="get">
          <label for="verification-get-query">Query</label>
          <input id="verification-get-query" name="q" value="original">
          <label for="verification-get-blank">Blank</label>
          <input id="verification-get-blank" name="blank" value="">
          <input type="hidden" name="tag[]" value="first">
          <input type="hidden" name="tag[]" value="second">
          <input type="hidden" name="shared" value="new">
          <button type="submit">Search Records</button>
        </form>
        <form id="verification-submitter-form" action="/verify/#{run_id}/static" method="post">
          <input type="hidden" name="_csrf_token" value="#{token}">
          <label for="verification-submitter-name">Submitter name</label>
          <input id="verification-submitter-name" name="person[name]" value="Original">
          <button type="submit" name="person[action]" value="first">First Action</button>
          <button type="submit" name="person[action]" value="second">Second Action</button>
          <button type="submit">Unnamed Action</button>
          <button type="submit" name="person[action]" value="redirected" formaction="/verify/#{run_id}/static/submitter">Redirected Action</button>
          <button type="submit" name="person[action]" value="search" formaction="/verify/#{run_id}/static/get" formmethod="get">Search Action</button>
        </form>
        <button type="submit" form="verification-submitter-form" name="person[action]" value="external">External Action</button>
        <form id="verification-put-form" action="/verify/#{run_id}/static/override" method="post">
          <input type="hidden" name="_csrf_token" value="#{token}">
          <input type="hidden" name="_method" value="put">
          <label for="verification-put-name">Update name</label>
          <input id="verification-put-name" name="person[name]" value="Original">
          <button type="submit">Update Record</button>
        </form>
        <form id="verification-delete-form" action="/verify/#{run_id}/static/override" method="post">
          <input type="hidden" name="_csrf_token" value="#{token}">
          <input type="hidden" name="_method" value="delete">
          <label for="verification-delete-reason">Delete reason</label>
          <input id="verification-delete-reason" name="reason" value="obsolete">
          <button type="submit">Remove Record</button>
        </form>
        <form id="verification-nested-form" action="/verify/#{run_id}/static" method="post">
          <input type="hidden" name="_csrf_token" value="#{token}">
          <input name="profile[tags][]" value="alpha">
          <input name="profile[contacts][0][name]" value="Ada">
          <input name="profile[contacts][0][role]" value="admin">
          <input name="profile[tags][]" value="beta">
          <input name="profile[contacts][1][name]" value="Lin">
          <input name="profile[contacts][1][role]" value="editor">
          <input name="profile[settings][theme]" value="dark">
          <input name="duplicate" value="first">
          <input name="duplicate" value="second">
          <button type="submit">Save Nested Data</button>
        </form>
        <form id="verification-defaults-form" action="/verify/#{run_id}/static" method="post">
          <input type="hidden" name="_csrf_token" value="#{token}">
          <label><input type="radio" name="person[choice]" value="ignored"> Ignored choice</label>
          <label><input type="radio" name="person[choice]" value="selected" checked> Selected choice</label>
          <label><input type="checkbox" name="person[standalone]" value="yes"> Standalone checkbox</label>
          <label for="verification-default-roles">Default roles</label>
          <select id="verification-default-roles" name="person[roles][]" multiple>
            <option value="admin">Admin</option>
            <option value="reader">Reader</option>
          </select>
          <label for="verification-default-text">Default text</label>
          <input id="verification-default-text" name="person[default_text]" value="Original">
          <label for="verification-default-choice">Default choice</label>
          <select id="verification-default-choice" name="person[default_choice]">
            <option value="first">First</option>
            <option value="second">Second</option>
          </select>
          <button type="submit">Save Defaults</button>
        </form>
        <form id="verification-disabled-readonly-form" action="/verify/#{run_id}/static" method="post">
          <input type="hidden" name="_csrf_token" value="#{token}">
          <label for="verification-active">Active</label>
          <input id="verification-active" name="person[active]" value="included">
          <label for="verification-disabled-text">Disabled text</label>
          <input id="verification-disabled-text" name="person[disabled_text]" value="excluded" disabled>
          <label for="verification-disabled-notes">Disabled notes</label>
          <textarea id="verification-disabled-notes" name="person[disabled_notes]" disabled>excluded notes</textarea>
          <label for="verification-disabled-choice">Disabled choice</label>
          <select id="verification-disabled-choice" name="person[disabled_choice]" disabled>
            <option value="excluded" selected>Excluded</option>
          </select>
          <label for="verification-disabled-check">Disabled check</label>
          <input id="verification-disabled-check" type="checkbox" name="person[disabled_check]" value="excluded" checked disabled>
          <label for="verification-readonly-text">Readonly text</label>
          <input id="verification-readonly-text" name="person[readonly_text]" value="locked" readonly>
          <label for="verification-readonly-notes">Readonly notes</label>
          <textarea id="verification-readonly-notes" name="person[readonly_notes]" readonly>locked notes</textarea>
          <button type="submit">Save Controls</button>
        </form>
      </body>
    </html>
    """)
  end

  def submit(conn, _params), do: html(conn, "Saved")
  def get_submit(conn, _params), do: html(conn, "Saved")
  def override_submit(conn, _params), do: html(conn, "Saved")
  def submitter_submit(conn, _params), do: html(conn, "Saved")
end
