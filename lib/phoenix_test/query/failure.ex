defmodule PhoenixTest.Query.Failure do
  @moduledoc false

  @enforce_keys [:kind, :operation, :request]
  defstruct [:kind, :operation, :request, :candidates, :labels]

  def new(kind, operation, request, opts \\ []) do
    %__MODULE__{
      kind: kind,
      operation: operation,
      request: request,
      candidates: Keyword.get(opts, :candidates, []),
      labels: Keyword.get(opts, :labels, [])
    }
  end
end
