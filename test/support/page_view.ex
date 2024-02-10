defmodule PhoenixTest.PageView do
  use Phoenix.Component

  def render("index.html", assigns) do
    ~H"""
    <h1 id="title" class="title" data-role="title">Main page</h1>

    <a href="/page/page_2">Page 2</a>

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

    <form action="/page/get_record">
      <button>Get record</button>
    </form>

    <form action="/page/update_record" method="put">
      <button>Mark as active</button>
    </form>

    <form action="/page/delete_record" method="delete">
      <button>Delete record</button>
    </form>

    <form action="/page/create_record" method="post" id="email-form">
      <label for="email">Email</label>
      <input name="email" />
      <button>Save</button>
    </form>

    <form action="/page/create_record" method="post" id="no-submit-button-form">
      <label for="name">Name</label>
      <input name="name" />
    </form>

    <form id="nested-form" method="post" action="/page/create_record">
      <label for="user[name]">Name</label>
      <input name="user[name]" />
    </form>

    <form id="full-form" method="post" action="/page/create_record">
      <label for="name">Name</label>
      <input name="name" />

      <label for="admin">Admin</label>
      <input type="checkbox" name="admin" />

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

      <div>
        <label for="member_of_fellowship">Member of fellowship</label>
        <input type="checkbox" name="member_of_fellowship" />
      </div>
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
      <label for="name">Name</label>
      <input name="name" />
    </form>
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
    <h1>Marked active!</h1>
    """
  end

  def render("record_deleted.html", assigns) do
    ~H"""
    <h1>Record deleted</h1>
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
