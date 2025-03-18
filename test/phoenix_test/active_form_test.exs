defmodule PhoenixTest.ActiveFormTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.ActiveForm
  alias PhoenixTest.FormData

  describe "add_form_data" do
    test "adds form data passed" do
      active_form =
        [id: "user-form", selector: "#user-form"]
        |> ActiveForm.new()
        |> ActiveForm.add_form_data({"user[name]", "Frodo"})

      assert FormData.has_data?(active_form.form_data, "user[name]", "Frodo")
    end
  end
end
