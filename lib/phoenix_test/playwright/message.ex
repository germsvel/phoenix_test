defmodule PhoenixTest.Playwright.Message do
  @moduledoc """
  Parse playwright messages.
  A single `Port` message can contain multiple Playwright messages and/or a fraction of a message.
  Such a message fraction is stored in `bufffer` and continued in the next `Port` message.
  """

  def parse(<<head::unsigned-little-integer-size(32)>>, 0, "", accumulated) do
    %{
      buffer: "",
      frames: accumulated,
      remaining: head
    }
  end

  def parse(<<head::unsigned-little-integer-size(32), data::binary>>, 0, "", accumulated) do
    parse(data, head, "", accumulated)
  end

  def parse(<<data::binary>>, read_length, buffer, accumulated) when byte_size(data) == read_length do
    %{
      buffer: "",
      frames: accumulated ++ [buffer <> data],
      remaining: 0
    }
  end

  def parse(<<data::binary>>, read_length, buffer, accumulated) when byte_size(data) > read_length do
    {message, tail} = bytewise_split(data, read_length)
    parse(tail, 0, "", accumulated ++ [buffer <> message])
  end

  def parse(<<data::binary>>, read_length, buffer, accumulated) when byte_size(data) < read_length do
    %{
      buffer: buffer <> data,
      frames: accumulated,
      remaining: read_length - byte_size(data)
    }
  end

  defp bytewise_split(input, offset) do
    <<head::size(offset)-binary, tail::binary>> = input
    {head, tail}
  end
end
