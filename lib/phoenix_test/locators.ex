defmodule PhoenixTest.Locators do
  @moduledoc false

  defmodule Button do
    @moduledoc false
    defstruct ~w[text selectors]a
  end

  def button(opts) do
    text = Keyword.get(opts, :text)

    selectors =
      ~w|button [role="button"] input[type="button"] input[type="image"] input[type="reset"] input[type="submit"]|

    %Button{text: text, selectors: selectors}
  end

  def role_selectors(%Button{} = button) do
    %Button{text: text, selectors: selectors} = button

    Enum.map(selectors, fn
      "button" -> {"button", text}
      ~s|[role="button"]| -> {~s|[role="button"]|, text}
      role -> role <> "[value=#{inspect(text)}]"
    end)
  end
end
