defmodule PhoenixTest.ActiveFormTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.ActiveForm
  alias PhoenixTest.FormData

  describe "put_form_data" do
    test "puts form data with given name and value" do
      active_form =
        [id: "user-form", selector: "#user-form"]
        |> ActiveForm.new()
        |> ActiveForm.put_form_data("user[name]", "Frodo")

      assert FormData.has_data?(active_form.form_data, "user[name]", "Frodo")
    end
  end
end
