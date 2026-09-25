defmodule PhoenixTest.Verification.RecorderTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.Verification.Recorder

  test "returns a recorded observation" do
    run_id = Integer.to_string(System.unique_integer([:positive]))
    Recorder.record(run_id, %{params: %{"name" => "Ada"}})

    assert Recorder.result(run_id) == %{params: %{"name" => "Ada"}}
  end

  test "keeps multiple observations in order and isolates runs" do
    run_id = Integer.to_string(System.unique_integer([:positive]))
    other_id = Integer.to_string(System.unique_integer([:positive]))

    Recorder.record(run_id, %{event: "first"})
    Recorder.record(other_id, %{event: "other"})
    Recorder.record(run_id, %{event: "second"})
    Recorder.record(run_id, %{event: "third"})

    assert Recorder.results(run_id, 2) == [%{event: "first"}, %{event: "second"}]
    assert Recorder.result(run_id) == %{event: "third"}
    assert Recorder.result(other_id) == %{event: "other"}
  end

  test "delivers successive observations to waiting callers once each" do
    run_id = Integer.to_string(System.unique_integer([:positive]))
    waiter = Task.async(fn -> Recorder.results(run_id, 2) end)
    Recorder.record(run_id, %{event: "first"})
    Recorder.record(run_id, %{event: "second"})

    assert Task.await(waiter) == [%{event: "first"}, %{event: "second"}]
  end
end
