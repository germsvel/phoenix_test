defprotocol PhoenixTest.Driver do
  @moduledoc """
  Protocol that both static (i.e. non-LiveView) and LiveView drivers implement.

  The protocol is open, so other libraries can implement it if they want to provide
  extensions, like using Phoenixtest with Wallaby or Playwright.

  The extensions are still experimental, and the protocol might change.
  """

  @type session :: struct()
  @type selectors :: String.t() | [String.t()]
  @type label :: String.t()
  @type exact_option :: {:exact, boolean()}

  @spec check(session(), label(), [exact_option()]) :: session()
  def check(session, label, opts)

  @spec check(session(), selectors(), label(), [exact_option()]) :: session()
  def check(session, input_selector, label, opts)

  @spec choose(session(), label(), [exact_option()]) :: session()
  def choose(session, label, opts)

  @spec choose(session(), selectors(), label(), [exact_option()]) :: session()
  def choose(session, input_selector, label, opts)

  @spec click_button(session(), String.t()) :: session()
  def click_button(session, text)

  @spec click_button(session(), selectors(), String.t()) :: session()
  def click_button(session, selector, text)

  @spec click_link(session(), String.t()) :: session()
  def click_link(session, text)

  @spec click_link(session(), selectors(), String.t()) :: session()
  def click_link(session, selector, text)

  @spec current_path(session()) :: String.t()
  def current_path(session)

  @type fill_in_opt :: {:with, String.t()} | exact_option()
  @spec fill_in(session(), label(), [fill_in_opt()]) :: session()
  def fill_in(session, label, opts)

  @spec fill_in(session(), selectors(), label(), [fill_in_opt()]) :: session()
  def fill_in(session, input_selector, label, opts)

  @spec open_browser(session()) :: term()
  def open_browser(session)

  @spec open_browser(session(), (session() -> term())) :: term()
  def open_browser(session, open_fun)

  @spec render_html(session()) :: String.t()
  def render_html(session)

  @spec render_page_title(session()) :: String.t()
  def render_page_title(session)

  @type option_to_select :: String.t()
  @type select_opt :: {:from, label()} | {:exact, boolean()} | {:exact_option, boolean()}
  @spec select(session(), option_to_select(), [select_opt()]) :: session()
  def select(session, option, opts)

  @spec select(session(), selectors(), option_to_select(), [select_opt()]) :: session()
  def select(session, input_selector, option, opts)

  @spec submit(session()) :: session()
  def submit(session)

  @spec uncheck(session(), label(), [exact_option()]) :: session()
  def uncheck(session, label, opts)

  @spec uncheck(session(), selectors(), label(), [exact_option()]) :: session()
  def uncheck(session, input_selector, label, opts)

  @spec unwrap(session(), (session() -> any())) :: session()
  def unwrap(session, fun)

  @spec upload(session(), label(), Path.t(), [exact_option()]) :: session()
  def upload(session, label, path, opts)

  @spec upload(session(), selectors(), label(), Path.t(), [exact_option()]) :: session()
  def upload(session, input_selector, label, path, opts)

  @spec visit(struct(), String.t()) :: session()
  def visit(initial_struct, path)

  @spec within(session(), selectors(), (session() -> any())) :: session()
  def within(session, selector, fun)

  ## Assertions

  @type assert_has_opt ::
          {:at, non_neg_integer()}
          | {:count, non_neg_integer()}
          | {:exact, boolean()}
          | {:text, String.t()}
          | {:timeout, non_neg_integer()}

  @spec assert_has(session(), selectors()) :: session()
  def assert_has(session, selector)

  @spec assert_has(session(), selectors(), [assert_has_opt()]) :: session()
  def assert_has(session, selector, opts)

  @spec refute_has(session(), selectors()) :: session()
  def refute_has(session, selector)

  @spec refute_has(session(), selectors(), [assert_has_opt()]) :: session()
  def refute_has(session, selector, opts)

  @type query_params :: {:query_params, %{atom() => String.t() | list()}}

  @spec assert_path(session(), String.t()) :: session()
  def assert_path(session, path)

  @spec assert_path(session(), String.t(), [query_params()]) :: session()
  def assert_path(session, path, opts)

  @spec refute_path(session(), String.t()) :: session()
  def refute_path(session, path)

  @spec refute_path(session(), String.t(), [query_params()]) :: session()
  def refute_path(session, path, opts)
end
