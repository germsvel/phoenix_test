defmodule PhoenixTest.Credo.NoOpenBrowserTest do
  use Credo.Test.Case

  alias PhoenixTest.Credo.NoOpenBrowser

  test "does NOT report if no open_browser() call present" do
    """
    defmodule SampleTest do
      use ExUnit.Case, async: true
      import PhoenixTest

      test "open browser" do
        Phoenix.ConnTest.build_conn()
        |> visit("/live/index")
      end
    end
    """
    |> to_source_file()
    |> run_check(NoOpenBrowser)
    |> refute_issues()
  end

  test "reports imported PhoenixTest.open_browser/1 call" do
    """
    defmodule SampleTest do
      use ExUnit.Case, async: true
      import PhoenixTest

      test "open browser" do
        Phoenix.ConnTest.build_conn()
        |> open_browser()
      end
    end
    """
    |> to_source_file()
    |> run_check(NoOpenBrowser)
    |> assert_issue()
  end

  test "reports fully qualified PhoenixTest.open_browser/1 call" do
    """
    defmodule SampleTest do
      use ExUnit.Case, async: true

      test "open browser" do
        Phoenix.ConnTest.build_conn()
        |> PhoenixTest.open_browser()
      end
    end
    """
    |> to_source_file()
    |> run_check(NoOpenBrowser)
    |> assert_issue()
  end

  @tag :skip
  test "reports aliased PhoenixTest.open_browser/1 call" do
    """
    defmodule SampleTest do
      use ExUnit.Case, async: true
      alias PhoenixTest, as: PT

      test "open browser" do
        Phoenix.ConnTest.build_conn()
        |> PT.open_browser()
      end
    end
    """
    |> to_source_file()
    |> run_check(NoOpenBrowser)
    |> assert_issue()
  end

  @tag :skip
  test "does NOT report imported Phoenix.LiveViewTest.open_browser/1 call" do
    """
    defmodule SampleTest do
      use ExUnit.Case, async: true
      import Phoenix.LiveViewTest

      test "open browser" do
        {:ok, view, _html} = live(Phoenix.ConnTest.build_conn(), "/live/index")
        open_browser(view)
      end
    end
    """
    |> to_source_file()
    |> run_check(NoOpenBrowser)
    |> refute_issues()
  end

  test "does NOT report fully qualified Phoenix.LiveViewTest.open_browser/1 call" do
    """
    defmodule SampleTest do
      use ExUnit.Case, async: true

      test "open browser" do
        {:ok, view, _html} = Phoenix.LiveViewTest.live(Phoenix.ConnTest.build_conn(), "/live/index")
        Phoenix.LiveViewTest.open_browser(view)
      end
    end
    """
    |> to_source_file()
    |> run_check(NoOpenBrowser)
    |> refute_issues()
  end

  @tag :skip
  test "does NOT report local open_browser() call" do
    """
    defmodule SampleTest do
      use ExUnit.Case, async: true

      test "open browser from other module" do
        open_browser(conn)
      end

      defp open_browser(_conn), do: nil
    end
    """
    |> to_source_file()
    |> run_check(NoOpenBrowser)
    |> refute_issues()
  end
end
