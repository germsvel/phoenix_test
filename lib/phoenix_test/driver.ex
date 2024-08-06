defprotocol PhoenixTest.Driver do
  @moduledoc false
  def render_page_title(session)
  def render_html(session)
  def click_link(session, selector, text)
  def click_button(session, selector, text)
  def fill_in_field_data(session, field)
  def submit(session)
  def unwrap(session, fun)
  def open_browser(session)
  def open_browser(session, open_fun)
  def current_path(session)

  def assert_has(session, selector)
  def assert_has(session, selector, opts)
  def refute_has(session, selector)
  def refute_has(session, selector, opts)
  def assert_path(session, path)
  def assert_path(session, path, opts)
  def refute_path(session, path)
  def refute_path(session, path, opts)
end
