defprotocol PhoenixTest.Driver do
  def click_link(session, text)
  def render_html(session)
end
