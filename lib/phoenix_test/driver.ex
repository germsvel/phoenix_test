defprotocol PhoenixTest.Driver do
  def click_link(session, text)
  def click_button(session, text)
  def render_html(session)
end
