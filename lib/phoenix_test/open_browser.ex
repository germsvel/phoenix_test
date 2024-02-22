defmodule PhoenixTest.OpenBrowser do
  @moduledoc false

  # This module contains private functionality ported over from
  # `Phoenix.LiveViewTest` to make `open_browser` work with `Static` tests.

  @doc """
  Fully qualifies static assets paths so the browser can find them.
  """
  def prefix_static_paths(node, endpoint) do
    static_path = static_path(endpoint)

    case node do
      # Remove script tags
      {"script", _, _} -> nil
      # Skip prefixing src attributes on anchor tags
      {"a", _, _} = link -> link
      {el, attrs, children} -> {el, maybe_prefix_static_path(attrs, static_path), children}
      el -> el
    end
  end

  defp static_path(endpoint) do
    static_url = endpoint.config(:static_url) || []
    priv_dir = :otp_app |> endpoint.config() |> Application.app_dir("priv")

    if Keyword.get(static_url, :path) do
      priv_dir
    else
      Path.join(priv_dir, "static")
    end
  end

  defp maybe_prefix_static_path(attrs, nil), do: attrs

  defp maybe_prefix_static_path(attrs, static_path) do
    Enum.map(attrs, fn
      {"src", path} -> {"src", prefix_static_path(path, static_path)}
      {"href", path} -> {"href", prefix_static_path(path, static_path)}
      attr -> attr
    end)
  end

  defp prefix_static_path(<<"//" <> _::binary>> = url, _prefix), do: url

  defp prefix_static_path(<<"/" <> _::binary>> = path, prefix) do
    "file://#{Path.join([prefix, path])}"
  end

  defp prefix_static_path(url, _), do: url

  @doc """
  System agnostic function to open the default browser with the given `path`.

  This is ripped verbatim from `Phoenix.LiveViewTest`.
  """
  def open_with_system_cmd(path) do
    {cmd, args} =
      case :os.type() do
        {:win32, _} ->
          {"cmd", ["/c", "start", path]}

        {:unix, :darwin} ->
          {"open", [path]}

        {:unix, _} ->
          if wsl?(path) do
            {"cmd.exe", ["/c", "start", path]}
          else
            {"xdg-open", [path]}
          end
      end

    System.cmd(cmd, args)
  end

  defp wsl?(path) do
    path =~ "\\" and System.find_executable("cmd.exe") != nil
  end
end
