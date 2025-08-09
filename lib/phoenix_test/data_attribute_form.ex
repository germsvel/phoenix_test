defmodule PhoenixTest.DataAttributeForm do
  @moduledoc false

  alias PhoenixTest.Html

  def build(%LazyHTML{} = element) do
    method = Html.attribute(element, "data-method")
    action = Html.attribute(element, "data-to")
    csrf_token = Html.attribute(element, "data-csrf")

    %{}
    |> Map.put(:method, method)
    |> Map.put(:action, action)
    |> Map.put(:csrf_token, csrf_token)
    |> Map.put(:element, element)
    |> Map.put(:data, %{"_csrf_token" => csrf_token, "_method" => method})
  end

  def validate!(form, selector, text) do
    method = form.method
    action = form.action
    csrf_token = form.csrf_token

    missing =
      Enum.filter(["data-method": method, "data-to": action, "data-csrf": csrf_token], fn {_, value} -> empty?(value) end)

    unless method && action && csrf_token do
      raise ArgumentError, """
      Tried submitting form via `data-method` but some data attributes are
      missing.

      I expected #{inspect(selector)} with text #{inspect(text)} to include
      data-method, data-to, and data-csrf.

      I found:

      #{Html.raw(form.element)}

      It seems these are missing: #{Enum.map_join(missing, ", ", fn {key, _} -> key end)}.

      NOTE: `data-method` form submissions happen through JavaScript. Tests
      emulate that, but be sure to verify you're including Phoenix.HTML.js!

      See: https://hexdocs.pm/phoenix_html/Phoenix.HTML.html#module-javascript-library
      """
    end

    form
  end

  defp empty?(value) do
    value == "" || value == nil
  end
end
