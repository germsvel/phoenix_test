defmodule PhoenixTest.WebApp.ErrorView do
  use Phoenix.Component

  def render(_template, assigns) do
    ~H"""
    <h2>{@status}</h2>
    <p>{inspect(@reason)}</p>
    """
  end
end
