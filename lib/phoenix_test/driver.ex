defprotocol PhoenixTest.Driver do
  @moduledoc false
  def visit(initial_struct, path)
  def render_page_title(session)
  def render_html(session)
  def click(session, selector)
  def click_link(session, text)
  def click_link(session, selector, text)
  def click_button(session, text)
  def click_button(session, selector, text)
  def within(session, selector, fun)
  def fill_in(session, label, opts)
  def fill_in(session, input_selector, label, opts)
  def select(session, option, opts)
  def select(session, input_selector, option, opts)
  def check(session, label, opts)
  def check(session, input_selector, label, opts)
  def uncheck(session, label, opts)
  def uncheck(session, input_selector, label, opts)
  def choose(session, label, opts)
  def choose(session, input_selector, label, opts)
  def upload(session, label, path, opts)
  def upload(session, input_selector, label, path, opts)
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
