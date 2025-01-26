defprotocol PhoenixTest.Driver do
  @moduledoc """
  Protocol that both static (i.e. non-LiveView) and LiveView drivers implement.

  The protocol is open, so other libraries can implement it if they want to provide
  extensions, like using Phoenixtest with Wallaby or Playwright.

  The extensions are still experimental, and the protocol might change.
  """

  @type t :: struct()
  @type selectors :: String.t() | [String.t()]
  @type label :: String.t()
  @type exact_option :: {:exact, boolean()}

  @spec check(t(), label(), [exact_option()]) :: t()
  def check(session, label, opts)

  @spec check(t(), selectors(), label(), [exact_option()]) :: t()
  def check(session, input_selector, label, opts)

  @spec choose(t(), label(), [exact_option()]) :: t()
  def choose(session, label, opts)

  @spec choose(t(), selectors(), label(), [exact_option()]) :: t()
  def choose(session, input_selector, label, opts)

  @spec click_button(t(), String.t()) :: t()
  def click_button(session, text)

  @spec click_button(t(), selectors(), String.t()) :: t()
  def click_button(session, selector, text)

  @spec click_link(t(), String.t()) :: t()
  def click_link(session, text)

  @spec click_link(t(), selectors(), String.t()) :: t()
  def click_link(session, selector, text)

  @spec current_path(t()) :: String.t()
  def current_path(session)

  @type fill_in_opt :: {:with, String.t()} | exact_option()
  @spec fill_in(t(), label(), [fill_in_opt()]) :: t()
  def fill_in(session, label, opts)

  @spec fill_in(t(), selectors(), label(), [fill_in_opt()]) :: t()
  def fill_in(session, input_selector, label, opts)

  @spec open_browser(t()) :: term()
  def open_browser(session)

  @spec open_browser(t(), (t() -> term())) :: term()
  def open_browser(session, open_fun)

  @spec render_html(t()) :: String.t()
  def render_html(session)

  @spec render_page_title(t()) :: String.t()
  def render_page_title(session)

  @type option_to_select :: String.t()
  @type select_opt :: {:from, label()} | {:exact, boolean()} | {:exact_option, boolean()}
  @spec select(t(), option_to_select(), [select_opt()]) :: t()
  def select(session, option, opts)

  @spec select(t(), selectors(), option_to_select(), [select_opt()]) :: t()
  def select(session, input_selector, option, opts)

  @spec submit(t()) :: t()
  def submit(session)

  @spec uncheck(t(), label(), [exact_option()]) :: t()
  def uncheck(session, label, opts)

  @spec uncheck(t(), selectors(), label(), [exact_option()]) :: t()
  def uncheck(session, input_selector, label, opts)

  @spec unwrap(t(), (t() -> any())) :: t()
  def unwrap(session, fun)

  @spec upload(t(), label(), Path.t(), [exact_option()]) :: t()
  def upload(session, label, path, opts)

  @spec upload(t(), selectors(), label(), Path.t(), [exact_option()]) :: t()
  def upload(session, input_selector, label, path, opts)

  @spec visit(struct(), String.t()) :: t()
  def visit(initial_struct, path)

  @spec within(t(), selectors(), (t() -> any())) :: t()
  def within(session, selector, fun)

  ## Assertions

  @type assert_has_opt ::
          {:at, non_neg_integer()}
          | {:count, non_neg_integer()}
          | {:exact, boolean()}
          | {:text, String.t()}
          | {:timeout, non_neg_integer()}

  @spec assert_has(t(), selectors()) :: t()
  def assert_has(session, selector)

  @spec assert_has(t(), selectors(), [assert_has_opt()]) :: t()
  def assert_has(session, selector, opts)

  @spec refute_has(t(), selectors()) :: t()
  def refute_has(session, selector)

  @spec refute_has(t(), selectors(), [assert_has_opt()]) :: t()
  def refute_has(session, selector, opts)

  @type query_params :: {:query_params, %{atom() => String.t() | list()}}

  @spec assert_path(t(), String.t()) :: t()
  def assert_path(session, path)

  @spec assert_path(t(), String.t(), [query_params()]) :: t()
  def assert_path(session, path, opts)

  @spec refute_path(t(), String.t()) :: t()
  def refute_path(session, path)

  @spec refute_path(t(), String.t(), [query_params()]) :: t()
  def refute_path(session, path, opts)
end
