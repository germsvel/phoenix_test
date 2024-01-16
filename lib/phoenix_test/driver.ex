defprotocol PhoenixTest.Driver do
  def click_link(session, text)
  def click_button(session, text)
  def submit_form(session, selector, form_data)
  def render_html(session)
end
