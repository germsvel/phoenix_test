defmodule PhoenixTest.FileUpload do
  @moduledoc false
  def mime_type(path) do
    if Code.ensure_loaded?(MIME) do
      "." <> ext = Path.extname(path)
      MIME.type(ext)
    else
      "application/octet-stream"
    end
  end
end
