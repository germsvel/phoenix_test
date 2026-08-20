defmodule PhoenixTest.QueryFailureTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.Query
  alias PhoenixTest.QueryFailure

  test "formats selector and text failures for action callers" do
    assert {:error, failure} = Query.find("<h1>Hello</h1>", "h1", "Goodbye")
    message = QueryFailure.argument_error_message(failure)

    assert message =~ ~s(Could not find element with selector "h1" and text "Goodbye".)
    assert message =~ "The following elements matching the selector were found:"
    assert message =~ "<h1>Hello</h1>"

    assert_raise ArgumentError, ~r/Could not find element with selector "h1" and text "Goodbye"/, fn ->
      QueryFailure.raise_argument_error!(failure)
    end
  end

  test "formats one-of and role failures with selector diagnostics" do
    assert {:error, failure} = Query.find_one_of("<h2>Hello</h2>", [{"h2", "No"}, "h3"])
    message = QueryFailure.argument_error_message(failure)

    assert message =~ "Could not find an element with given selectors."
    assert message =~ ~s(- "h2" with content "No")
    assert message =~ ~s(- "h3")
    assert message =~ "<h2>Hello</h2>"

    locator = PhoenixTest.Locators.button(text: "Save")
    assert {:error, role_failure} = Query.find_by_role("<p>Nothing</p>", locator)
    assert QueryFailure.argument_error_message(role_failure) =~ "Could not find an element with given selectors."
  end

  test "formats label diagnostics" do
    assert {:error, missing_for} = Query.find_by_label("<label>Name</label>", "input", "Name")
    assert QueryFailure.argument_error_message(missing_for) =~ "Found label, but it doesn't have `for` attribute."

    assert {:error, missing_input} =
             Query.find_by_label("<label for=\"name\">Name</label><input name=\"name\" />", "input", "Name")

    assert QueryFailure.argument_error_message(missing_input) =~
             "Found label but can't find labeled element whose `id` matches label's `for` attribute."

    html = "<label for=\"one\">Name</label><input id=\"one\" /><label for=\"two\">Name</label><input id=\"two\" />"
    assert {:error, many} = Query.find_by_label(html, "input", "Name")
    assert QueryFailure.argument_error_message(many) =~ "Found many elements with label \"Name\""
  end

  test "formats ancestor diagnostics" do
    assert {:error, missing} = Query.find_ancestor("<form></form>", "form", {"button", "Save"})

    assert QueryFailure.argument_error_message(missing) =~
             "Could not find \"form\" for an element with selector \"button\" and text \"Save\"."

    html = "<form><button>Save</button></form><form><button>Save</button></form>"
    assert {:error, many} = Query.find_ancestor(html, "form", {"button", "Save"})
    assert QueryFailure.argument_error_message(many) =~ "Found too many \"form\" elements with nested element"
  end

  test "formats assertion failures using the existing assertion wording" do
    assert {:error, failure} = Query.find("<p>Other</p>", "p", "Expected")

    assert QueryFailure.assertion_message(failure, "p",
             count: :any,
             text: "Expected",
             value: :no_value,
             selected: :no_selected,
             checked: :no_checked,
             label: :no_label,
             at: :any
           ) ==
             "Could not find any elements with selector \"p\" and text \"Expected\"\n\nFound these elements matching the selector \"p\":\n\n<p>Other</p>"
  end
end
