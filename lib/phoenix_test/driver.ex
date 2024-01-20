defprotocol PhoenixTest.Driver do
  @doc false
  def render_html(session)
  def click_link(session, text)
  def click_button(session, text)
  def fill_form(session, selector, form_data)
  def submit_form(session, selector, form_data)
end
