defprotocol PhoenixTest.Driver do
  @moduledoc false

  @type session :: struct()
  @type selectors :: String.t() | [String.t()]
  @type label :: String.t()

  @spec visit(struct(), String.t()) :: session()
  def visit(initial_struct, path)

  @spec render_page_title(session()) :: String.t()
  def render_page_title(session)

  @spec render_html(session()) :: String.t()
  def render_html(session)

  @spec click_link(session(), String.t()) :: session()
  def click_link(session, text)

  @spec click_link(session(), selectors(), String.t()) :: session()
  def click_link(session, selector, text)

  @spec click_button(session(), String.t()) :: session()
  def click_button(session, text)

  @spec click_button(session(), selectors(), String.t()) :: session()
  def click_button(session, selector, text)

  @spec within(session(), selectors(), (session() -> any())) :: session()
  def within(session, selector, fun)

  @type fill_in_opt :: {:with, String.t()} | {:exact, boolean()}

  @spec fill_in(session(), label(), [fill_in_opt()]) :: session()
  def fill_in(session, label, opts)

  @spec fill_in(session(), selectors(), label(), [fill_in_opt()]) :: session()
  def fill_in(session, input_selector, label, opts)

  @type option_to_select :: String.t()
  @type select_opt :: {:from, label()} | {:exact, boolean()} | {:exact_option, boolean()}

  @spec select(session(), option_to_select(), [select_opt()]) :: session()
  def select(session, option, opts)

  @spec select(session(), selectors(), option_to_select(), [select_opt()]) :: session()
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
