defmodule PhoenixTest.WebApp.DynamicFormLive do
  @moduledoc false

  use Phoenix.LiveView

  def render(assigns) do
    ~H"""
    <h1>Dynamic Form Test</h1>
    <button phx-click="show-form">Show Form</button>

    <form
      :if={@show_form}
      id="dynamic-form"
      phx-submit="submit-form"
      phx-trigger-action={@trigger_submit}
      action="/page/create_record"
      method="post"
    >
      <label for="message">Message</label>
      <input id="message" name="message" />
      <button type="submit">Submit</button>
    </form>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, show_form: false, trigger_submit: false)}
  end

  def handle_event("show-form", _, socket) do
    {:noreply, assign(socket, :show_form, true)}
  end

  def handle_event("submit-form", _params, socket) do
    {:noreply, assign(socket, :trigger_submit, true)}
  end
end
