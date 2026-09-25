defmodule PhoenixTest.Verification.RecorderTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.Verification.Recorder

  test "returns a recorded observation" do
    run_id = Integer.to_string(System.unique_integer([:positive]))
    Recorder.record(run_id, %{params: %{"name" => "Ada"}})

    assert Recorder.result(run_id) == %{params: %{"name" => "Ada"}}
  end
end
