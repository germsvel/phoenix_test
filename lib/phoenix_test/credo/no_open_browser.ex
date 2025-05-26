if Code.ensure_loaded?(Credo) do
  defmodule PhoenixTest.Credo.NoOpenBrowser do
    @moduledoc false

    use Credo.Check,
      base_priority: :normal,
      category: :warning,
      explanations: [
        check: """
        The `open_browser/1` function is useful during development but should not be
        committed in tests as it would open browsers during CI runs, which can cause
        unexpected behavior and CI failures.

        A Credo check that disallows the use of `open_browser/1` in test code.

        ## Usage

        Add this check to your `.credo.exs` file:

        ```elixir
        %{
          configs: [
            %{
              name: "default",
              requires: ["./deps/phoenix_test/lib/phoenix_test/credo/**/*.ex"],
              checks: [
                {PhoenixTest.Credo.NoOpenBrowser, []}
              ]
            }
          ]
        }
        ```
        """
      ]

    def run(source_file, params \\ []) do
      issue_meta = IssueMeta.for(source_file, params)
      Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
    end

    defp traverse({:open_browser, meta, _} = ast, issues, issue_meta) do
      {ast, issues ++ [issue_for(meta[:line], issue_meta)]}
    end

    defp traverse({:., meta, [{:__aliases__, _, [:PhoenixTest]}, :open_browser]} = ast, issues, issue_meta) do
      {ast, issues ++ [issue_for(meta[:line], issue_meta)]}
    end

    defp traverse(ast, issues, _issue_meta) do
      {ast, issues}
    end

    defp issue_for(line_no, issue_meta) do
      format_issue(
        issue_meta,
        message: "There should be no `open_browser` calls.",
        line_no: line_no
      )
    end
  end
end
