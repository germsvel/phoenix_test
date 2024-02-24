defprotocol PhoenixTest.Driver do
  @moduledoc false
  def render_page_title(session)
  def render_html(session)
  def render_html(session, status)
  def click_link(session, text)
  def click_link(session, selector, text)
  def click_button(session, text)
  def click_button(session, selector, text)
  def fill_form(session, selector, form_data)
  def submit_form(session, selector, form_data)
  def open_browser(session)
  def open_browser(session, open_fun)
end
