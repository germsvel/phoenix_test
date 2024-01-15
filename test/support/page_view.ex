defmodule PhoenixTest.PageView do
  use Phoenix.Component

  def render("index.html", assigns) do
    ~H"""
      <h1 id="title" class="title" data-role="title">Main page</h1>

      <a href="/page/page_2">Page 2</a>

      <a class="multiple_links" href="/page/page_3">Multiple links</a>
      <a class="multiple_links" href="/page/page_4">Multiple links</a>
    """
  end

  def render("page_2.html", assigns) do
    ~H"""
      <h1>Page 2</h1>
    """
  end

  def render("page_3.html", assigns) do
    ~H"""
      <h1>Page 3</h1>
    """
  end
end
