defmodule PhoenixTest.FormComponentsBenchmark do
  @moduledoc """
  Breakdown of local work for a LiveView checkbox interaction. No change
  events are dispatched here; this measures PhoenixTest's lookup and form
  bookkeeping separately from the LiveView round-trip.
  """
  use ExUnit.Case, async: false

  alias PhoenixTest.Element.Field
  alias PhoenixTest.FormData
  alias PhoenixTest.Html
  alias PhoenixTest.Query

  test "checkbox stages" do
    session = PhoenixTest.visit(Phoenix.ConnTest.build_conn(), "/live/index")
    html = PhoenixTest.Live.render_html(session)
    field = Field.find_checkbox!(html, "input[type='checkbox']", "Admin", [])
    form = Field.parent_form!(field, html)

    Benchee.run(
      %{
        "render and parse" => fn -> PhoenixTest.Live.render_html(session) end,
        "find field" => fn -> Field.find_checkbox!(html, "input[type='checkbox']", "Admin", []) end,
        "find matching label" => fn -> Query.find(html, "label", "Admin", exact: true) end,
        "match labels without native prefilter" => fn ->
          html
          |> Html.all("label")
          |> Enum.filter(&(Html.element_text(&1) == "Admin"))
        end,
        "query all labels" => fn -> Html.all(html, "label") end,
        "find associated input" => fn -> Query.find(html, "input[type='checkbox'][id='admin']") end,
        "find parent form and build default data" => fn -> Field.parent_form!(field, html) end,
        "build change payload" => fn ->
          names = PhoenixTest.Element.Form.form_element_names(form)

          form.form_data
          |> FormData.override(session.active_form.form_data)
          |> FormData.filter(&(&1.name in names))
          |> PhoenixTest.FormPayload.new()
        end,
        "find changeable field names" => fn -> PhoenixTest.Element.Form.changeable_field_names(form) end
      },
      warmup: 1,
      time: 2
    )
  end
end
