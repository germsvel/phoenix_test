defmodule PhoenixTest.FileDownload do
  @moduledoc false
  @enforce_keys ~w[name mime_type content]a
  defstruct ~w[name mime_type content]a
end
