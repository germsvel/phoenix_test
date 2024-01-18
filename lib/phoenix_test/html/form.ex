defmodule PhoenixTest.Html.Form do
  def parse({"form", attrs, fields}) do
    %{}
    |> put_attributes(attrs)
    |> Map.put("inputs", build_inputs(fields))
  end

  defp put_attributes(form, attrs) do
    attrs
    |> Enum.reduce(form, fn {key, value}, acc ->
      Map.put(acc, key, value)
    end)
  end

  defp build_inputs(fields) do
    fields
    |> Enum.filter(fn
      {"input", _, _} -> true
      _ -> false
    end)
    |> Enum.map(fn
      {"input", attrs, contents} ->
        %{}
        |> put_attributes(attrs)
        |> Map.put("content", Enum.join(contents, " "))
    end)
  end
end
