defmodule PhoenixTest.PageView do
  use Phoenix.Component

  def render("empty_layout.html", assigns) do
    ~H"""
    <%= @inner_content %>
    """
  end

  def render("layout.html", assigns) do
    ~H"""
    <html lang="en">
      <head>
        <title><%= assigns[:page_title] || "PhoenixTest is the best!" %></title>
        <link rel="stylesheet" href="/assets/app.css" />
        <link rel="stylesheet" href="//example.com/cool-styles.css" />
        <script>
          console.log("Hey, I'm some JavaScript!")
        </script>
        <style>
          body { font-size: 12px; }
        </style>
      </head>
      <body>
        <%= @inner_content %>
      </body>
    </html>
    """
  end

  def render("index.html", assigns) do
    ~H"""
    <h1 id="title" class="title" data-role="title">Main page</h1>

    <a href="/page/page_2">Page 2</a>

    <a href="/page/no_page?redirect_to=/page/index">Navigate away and redirect back</a>

    <a class="multiple_links" href="/page/page_3">Multiple links</a>
    <a class="multiple_links" href="/page/page_4">Multiple links</a>

    <a href="/live/index">To LiveView!</a>

    <ul id="multiple-items">
      <li>Aragorn</li>
      <li>Legolas</li>
      <li>Gimli</li>
    </ul>

    <div class="has_extra_space">
      &nbsp; Has extra space &nbsp;
    </div>

    <a href="/users/2" data-method="delete">Incomplete data-method Delete</a>

    <a
      href="/page/delete_record"
      data-method="delete"
      data-to="/page/delete_record"
      data-csrf="sometoken"
    >
      Data-method Delete
    </a>

    <button data-method="delete">Incomplete data-method Delete</button>

    <button data-method="delete" data-to="/page/delete_record" data-csrf="sometoken">
      Data-method Delete
    </button>

    <form action="/page/get_record">
      <button>Get record</button>
    </form>

    <form action="/page/update_record" method="post">
      <input name="_method" type="hidden" value="put" />
      <button>Mark as active</button>
    </form>

    <form action="/page/delete_record" method="post">
      <input name="_method" type="hidden" value="delete" />
      <button>Delete record</button>
    </form>

    <form action="/page/create_record" method="post" id="email-form">
      <label for="email">Email</label>
      <input type="text" id="email" name="email" />
      <button type="submit">Save Email</button>
    </form>

    <form id="update-form" action="/page/update_record" method="post">
      <input name="_method" type="hidden" value="put" />
      <label for="update-form-name">Name</label>
      <input id="update-form-name" name="name" />
    </form>

    <form action="/page/create_record" method="post" id="no-submit-button-form">
      <label for="no-submit-button-form-name">Name</label>
      <input id="no-submit-button-form-name" name="name" />
    </form>

    <form action="/page/create_record" method="post" id="pre-rendered-data-form">
      <input name="input" value="value" />

      <div><span>Test</span></div>

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

    <form id="nested-form" method="post" action="/page/create_record">
      <label for="user_name">User Name</label>
      <input type="text" id="user_name" name="user[name]" />

      <label for="user_admin">User Admin</label>
      <select id="user_admin" name="user[admin]">
        <option value="true">True</option>
        <option value="false">False</option>
      </select>

      <button name="save-button" value="nested-form-save">Save Nested Form</button>
    </form>

    <form id="full-form" method="post" action="/page/create_record">
      <label for="name">First Name</label>
      <input type="text" id="name" name="name" />

      <label for="date">Date</label>
      <input type="date" id="date" name="date" />

      <input type="hidden" name="admin" value="off" />
      <label for="admin">Admin</label>
      <input id="admin" type="checkbox" name="admin" />

      <label for="admin_boolean">Admin (boolean)</label>
      <input id="admin_boolean" type="checkbox" name="admin_boolean" value="true" />

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

      <div>
        <label for="member_of_fellowship">Member of fellowship</label>
        <input type="checkbox" name="member_of_fellowship" />
      </div>

      <button name="full_form_button" value="save">Save Full Form</button>
    </form>

    <form id="redirect-to-liveview-form" method="post" action="/page/redirect_to_liveview">
      <label for="name">Name</label>
      <input name="name" />
      <button type="submit">Save and Redirect to LiveView</button>
    </form>

    <form method="post" action="/page/redirect_to_liveview">
      <button>Post and Redirect</button>
    </form>

    <form id="no-submit-button-and-redirect" method="post" action="/page/redirect_to_liveview">
      <label for="no-submit-and-redirect-name">Name</label>
      <input id="no-submit-and-redirect-name" name="name" />
    </form>

    <form id="no-button-form" method="post" action="/page/create_record">
      <label for="no-button-form-country">Country of Origin</label>
      <input type="text" id="no-button-form-country" name="country" />
    </form>

    <button type="button">Actionless Button</button>
    """
  end

  def render("page_2.html", assigns) do
    ~H"""
    <h1>Page 2</h1>
    """
  end

  def render("page_3.html", assigns) do
    ~H"""
    <h1>Page 3</h1>
    """
  end

  def render("get_record.html", assigns) do
    ~H"""
    <h1>Record received</h1>
    """
  end

  def render("record_created.html", assigns) do
    ~H"""
    <h1>Record created</h1>

    <div id="form-data">
      <%= for {key, value} <- @params do %>
        <%= render_input_data(key, value) %>
      <% end %>
    </div>
    """
  end

  def render("record_updated.html", assigns) do
    ~H"""
    <h1>Record updated</h1>

    <div id="form-data">
      <%= for {key, value} <- @params do %>
        <%= render_input_data(key, value) %>
      <% end %>
    </div>
    """
  end

  def render("record_deleted.html", assigns) do
    ~H"""
    <h1>Record deleted</h1>
    """
  end

  def render("unauthorized.html", assigns) do
    ~H"""
    <h1>Unauthorized</h1>
    """
  end

  defp render_input_data(key, value) when is_boolean(value) do
    "#{key}: #{to_string(value)}"
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
