defmodule PhoenixTest.ReadonlyTest do
  use ExUnit.Case, async: true

  import PhoenixTest

  alias PhoenixTest.Verification.Recorder

  setup do
    %{conn: Phoenix.ConnTest.build_conn(), run_id: Integer.to_string(System.unique_integer([:positive]))}
  end

  for kind <- ~w(live static) do
    test "#{kind} rejects filling readonly inputs and textareas", %{conn: conn, run_id: run_id} do
      session = visit(conn, "/verify/#{run_id}/#{unquote(kind)}")

      for label <- ["Readonly text", "Readonly notes"] do
        assert_raise ArgumentError, ~r/Cannot fill in .* because it is readonly/, fn ->
          fill_in(session, label, with: "changed")
        end
      end
    end

    test "#{kind} rejects filling a readonly field by selector", %{conn: conn, run_id: run_id} do
      session = visit(conn, "/verify/#{run_id}/#{unquote(kind)}")

      assert_raise ArgumentError, ~r/Cannot fill in "Readonly text" because it is readonly/, fn ->
        fill_in(session, "#verification-readonly-text", "Readonly text", with: "changed")
      end
    end

    test "#{kind} submits the original readonly values", %{conn: conn, run_id: run_id} do
      conn
      |> visit("/verify/#{run_id}/#{unquote(kind)}")
      |> click_button("Save Controls")

      observation = Recorder.result(run_id)

      assert observation.params["person"]["readonly_text"] == "locked"
      assert observation.params["person"]["readonly_notes"] == "locked notes"
    end
  end
end
