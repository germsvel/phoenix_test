defmodule PhoenixTest.QueryTest do
  use ExUnit.Case, async: true

  import PhoenixTest.TestHelpers

  alias PhoenixTest.Query

  describe "find!/2" do
    test "finds element with selector (like find/2)" do
      html = """
      <h1>Hello</h1>
      """

      element = Query.find!(html, "h1")

      assert {"h1", _, ["Hello"]} = element
    end

    test "raises error if no element is found" do
      html = """
      <h1 id="title">Hello</h1>
      """

      assert_raise ArgumentError, ~r/Could not find element with selector/, fn ->
        Query.find!(html, ".no-value")
      end
    end

    test "raises an error if more than one element is found" do
      html = """
      <div class="greeting">Hello</div>
      <div class="greeting">Hi</div>
      """

      assert_raise ArgumentError, ~r/Found more than one element with selector/, fn ->
        Query.find!(html, ".greeting")
      end
    end
  end

  describe "find!/3" do
    test "finds element with selector (like find/3)" do
      html = """
      <h1>Hello</h1>
      """

      element = Query.find!(html, "h1", "Hello")

      assert {"h1", _, ["Hello"]} = element
    end

    test "raises error if no element is found" do
      html = """
      <h1 id="title">Hello</h1>
      """

      assert_raise ArgumentError, ~r/Could not find element with selector/, fn ->
        Query.find!(html, ".no-value", "Hello")
      end
    end

    test "raises an error if more than one element is found" do
      html = """
      <div class="greeting">Hello</div>
      <div class="greeting">Hello</div>
      """

      assert_raise ArgumentError, ~r/Found more than one element with selector/, fn ->
        Query.find!(html, ".greeting", "Hello")
      end
    end
  end

  describe "find/2" do
    test "finds element with tag" do
      html = """
      <h1>Hello</h1>
      """

      {:found, element} = Query.find(html, "h1")

      assert {"h1", _, ["Hello"]} = element
    end

    test "finds element with an attribute selector" do
      html = """
      <h1 id="title">Hello</h1>
      """

      {:found, element} = Query.find(html, "#title")

      assert {"h1", [{"id", "title"}], ["Hello"]} = element
    end

    test "finds elements if multiple match selector" do
      html = """
      <div class="greeting">Hello</div>
      <div class="greeting">Hi</div>
      """

      {:found_many, [el1, el2]} = Query.find(html, ".greeting")

      assert {"div", [{"class", "greeting"}], ["Hello"]} = el1
      assert {"div", [{"class", "greeting"}], ["Hi"]} = el2
    end

    test "returns :not_found if selector doesn't match an element" do
      html = """
      <h1 id="title">Hello</h1>
      """

      assert :not_found = Query.find(html, ".no-value")
    end
  end

  describe "find/3" do
    test "finds element with tag and text" do
      html = """
      <h1>Hello</h1>
      """

      {:found, element} = Query.find(html, "h1", "Hello")

      assert {"h1", _, ["Hello"]} = element
    end

    test "ignores element's extra whitespace" do
      html = """
      <h1>Hello       </h1>
      """

      {:found, element} = Query.find(html, "h1", "Hello")

      assert {"h1", _, ["Hello       "]} = element
    end

    test "matches on exact text if required" do
      html = """
      <h1>Hello world</h1>
      """

      assert {:found, _} = Query.find(html, "h1", "Hello")
      assert {:not_found, _} = Query.find(html, "h1", "Hello", exact: true)
    end

    test "finds an element with attribute selector and text" do
      html = """
      <h1 id="title">Hello</h1>
      """

      {:found, element} = Query.find(html, "#title", "Hello")

      assert {"h1", [{"id", "title"}], ["Hello"]} = element
    end

    test "finds elements if multiple match selector AND text" do
      html = """
      <div class="greeting">Hello</div>
      <div class="greeting">Hello</div>
      """

      {:found_many, [el1, el2]} = Query.find(html, ".greeting", "Hello")

      assert {"div", [{"class", "greeting"}], ["Hello"]} = el1
      assert {"div", [{"class", "greeting"}], ["Hello"]} = el2
    end

    test "only returns element `at` (1-based index) if requested" do
      html = """
      <div id="1" class="greeting">Hello</div>
      <div id="2" class="greeting">Hello</div>
      """

      {:found, el} = Query.find(html, ".greeting", "Hello", at: 2)

      assert {"div", [{"id", "2"}, _], ["Hello"]} = el
    end

    test "finds element with text if multiple match CSS selector" do
      html = """
      <div class="greeting">Hello</div>
      <div class="greeting">Hi</div>
      """

      {:found, element} = Query.find(html, ".greeting", "Hello")

      assert {"div", [{"class", "greeting"}], ["Hello"]} = element
    end

    test "returns :not_found if selector and text don't match an element" do
      html = """
      <h1 id="title">Hello</h1>
      """

      assert {:not_found, []} = Query.find(html, ".no-value", "no value")
    end

    test "returns :not_found with elements that matched selector but not text (if any)" do
      html = """
      <h1 id="title">Hello</h1>
      """

      assert {:not_found, [element]} = Query.find(html, "h1", "no value")
      assert {"h1", [{"id", "title"}], ["Hello"]} = element
    end
  end

  describe "find_one_of!/2" do
    test "returns element when one matches" do
      html = """
      <h1 id="title">Hello</h1>
      <h2 id="subtitle">Hi</h2>
      """

      element = Query.find_one_of!(html, [{"h1", "Hello"}, {"h2", "Hi"}])

      assert {"h1", _, ["Hello"]} = element
    end

    test "returns first element if multiple match" do
      html = """
      <h2>Hello</h2>
      <h2>Greetings</h2>
      """

      element = Query.find_one_of!(html, ["h2"])

      assert {"h2", _, ["Hello"]} = element
    end

    test "raises an error when element could not be found" do
      html = """
      <h1>Hello</h1>
      """

      msg = """
      Could not find an element with given selectors.

      I was looking for an element with one of these selectors:

      - "h2" with content "Hi"
      - "h3"
      """

      assert_raise ArgumentError, msg, fn ->
        Query.find_one_of!(html, [{"h2", "Hi"}, "h3"])
      end
    end

    test "raises error including potential matches when there are some" do
      html = """
      <h2>Hello</h2>
      <h2>Greetings</h2>
      """

      msg =
        """
        Could not find an element with given selectors.

        I was looking for an element with one of these selectors:

        - "h2" with content "Hi"
        - "h3"

        I found some elements that match the selector but not the content:

        <h2>
          Hello
        </h2>

        <h2>
          Greetings
        </h2>
        """
        |> ignore_whitespace()

      assert_raise ArgumentError, msg, fn ->
        Query.find_one_of!(html, [{"h2", "Hi"}, "h3"])
      end
    end
  end

  describe "find_one_of/2" do
    test "finds one of elements that match passed selectors" do
      html = """
      <h1 id="title">Hello</h1>
      <h2 id="subtitle">Hi</h2>
      """

      {:found, element} = Query.find_one_of(html, [{"h1", "Hello"}, {"h2", "Hi"}])

      assert {"h1", _, ["Hello"]} = element
    end

    test "finds elements with selector or selector and text" do
      html = """
      <h1 id="title">Hello</h1>
      <h2 id="subtitle">Hi</h2>
      """

      assert {:found, _element} = Query.find_one_of(html, [{"h1", "Hello"}])
      assert {:found, element} = Query.find_one_of(html, ["h1"])
      assert {"h1", [{"id", "title"}], ["Hello"]} = element
    end

    test "returns :not_found when no selector matches" do
      html = """
      <h2>Hello</h2>
      <h2>Greetings</h2>
      """

      assert {:not_found, []} = Query.find_one_of(html, ["h1"])

      assert {:not_found, matched_selector_but_not_text} =
               Query.find_one_of(html, [{"h2", "Hi"}])

      [a, b] = matched_selector_but_not_text
      assert {"h2", _, ["Hello"]} = a
      assert {"h2", _, ["Greetings"]} = b
    end
  end

  describe "find_by_label!/2" do
    test "raises error if no label is found" do
      html = """
      <input id="name"/>
      """

      msg = """
      Could not find element with label "Name"
      """

      assert_raise ArgumentError, msg, fn ->
        Query.find_by_label!(html, "Name")
      end
    end

    test "raises if label isn't found (but other labels are present)" do
      html = """
      <label for="name">Names</label>
      """

      msg = """
      Could not find element with label "Name".

      Found the following labels:

      <label for="name">
        Names
      </label>\n
      """

      assert_raise ArgumentError, msg, fn ->
        Query.find_by_label!(html, "Name")
      end
    end

    test "raises error if label doesn't have a `for` attribute" do
      html = """
      <label>Name</label>
      """

      msg =
        """
        Found label but doesn't have `for` attribute.

        (Label's `for` attribute must point to element's `id`)

        Label found:

        <label>
          Name
        </label>\n
        """

      assert_raise ArgumentError, msg, fn ->
        Query.find_by_label!(html, "Name")
      end
    end

    test "raises error if label's `for` doesn't have corresponding `id`" do
      html = """
      <label for="name">Name</label>
      <input type="text" name="name" />
      """

      msg = """
      Found label but could not find corresponding element with matching `id`.

      (Label's `for` attribute must point to element's `id`)

      Label found:

      <label for="name">
        Name
      </label>\n
      """

      assert_raise ArgumentError, msg, fn ->
        Query.find_by_label!(html, "Name")
      end
    end

    test "raises error if multiple multiple labels match" do
      html = """
      <label for="greeting">Hello</label>
      <label for="second_greeting">Hello</label>
      """

      msg = """
      Found many elements with label "Hello":

      <label for="greeting">
        Hello
      </label>

      <label for="second_greeting">
        Hello
      </label>\n
      """

      assert_raise ArgumentError, msg, fn ->
        Query.find_by_label!(html, "Hello")
      end
    end

    test "returns found element" do
      html = """
      <label for="greeting">Hello</label>
      <input id="greeting"/>
      """

      element = Query.find_by_label!(html, "Hello")

      assert {"input", [{"id", "greeting"}], []} = element
    end

    test "returns found element when association is implicit" do
      html = """
      <label>
        Hello
        <input name="greeting" />
      </label>
      """

      element = Query.find_by_label!(html, "Hello")

      assert {"input", [{"name", "greeting"}], []} = element
    end
  end

  describe "find_by_label/2" do
    test "returns error if no label is found" do
      html = """
      <input id="name"/>
      """

      assert {:not_found, :no_label, []} = Query.find_by_label(html, "Name")
    end

    test "returns error with other labels if others are found" do
      html = """
      <label name="name">Helpful for typo</label>
      """

      {:not_found, :no_label, [potential_match]} = Query.find_by_label(html, "Name")

      assert {"label", _, ["Helpful for typo"]} = potential_match
    end

    test "returns error if label doesn't have `for` attribute set" do
      html = """
      <label>Name</label>
      """

      {:not_found, :missing_for, label_without_for_element} = Query.find_by_label(html, "Name")

      assert {"label", _, ["Name"]} = label_without_for_element
    end

    test "returns error if label's for doesn't have matching element with id" do
      html = """
      <label for="name">Name</label>
      <input type="text" name="name" />
      """

      {:not_found, :missing_id, found_label} = Query.find_by_label(html, "Name")

      assert {"label", _, ["Name"]} = found_label
    end

    test "returns matching elements if multiple labels match" do
      html = """
      <label for="greeting">Hello</label>
      <label for="second_greeting">Hello</label>
      """

      {:not_found, :found_many_labels, elements} = Query.find_by_label(html, "Hello")

      assert Enum.count(elements) == 2
    end

    test "returns the element the label points to" do
      html = """
      <label for="greeting">Hello</label>
      <input id="greeting"/>
      """

      {:found, element} = Query.find_by_label(html, "Hello")

      assert {"input", [{"id", "greeting"}], []} = element
    end

    test "returns found element when association is implicit" do
      html = """
      <label>
        Hello
        <input name="greeting" />
      </label>
      """

      {:found, element} = Query.find_by_label(html, "Hello")

      assert {"input", [{"name", "greeting"}], []} = element
    end

    test "handles multiple linputs when implicit and one is hidden" do
      html = """
      <label>
        Checkbox
        <input type="hidden" name="admin" value="false" />
        <input type="checkbox" name="admin" value="true" />
      </label>
      """

      {:found, element} = Query.find_by_label(html, "Checkbox")

      assert {"input", [{"type", "checkbox"}, {"name", "admin"}, {"value", "true"}], []} = element
    end
  end

  describe "find_ancestor!/3" do
    test "returns specified ancestor element of given selector" do
      html = """
      <form id="super-form">
        <input id="greeting" />
      </form>
      """

      element = Query.find_ancestor!(html, "form", "#greeting")

      assert {"form", [{"id", "super-form"}], _} = element
    end

    test "raises error if cannot find ancestor element (but there are matches)" do
      html = """
      <form id="super-form">
      </form>
      <input id="greeting" />
      """

      msg = """
      Could not find "form" for an element with selector "#greeting".

      Found other potential "form":

      <form id="super-form">
      </form>\n
      """

      assert_raise ArgumentError, msg, fn ->
        Query.find_ancestor!(html, "form", "#greeting")
      end
    end

    test "raises error if cannot find any elements like ancestor" do
      html = """
      <input id="greeting" />
      """

      msg = """
      Could not find any "form" elements.
      """

      assert_raise ArgumentError, msg, fn ->
        Query.find_ancestor!(html, "form", "#greeting")
      end
    end
  end

  describe "find_ancestor!/3 with complex selector + text filter" do
    test "returns specified ancestor element of given selector and text filter" do
      html = """
      <form id="super-form">
        <button>Save</button>
      </form>

      <form id="other-form">
        <button>Reset</button>
      </form>
      """

      element = Query.find_ancestor!(html, "form", {"button", "Save"})

      assert {"form", [{"id", "super-form"}], _} = element
    end

    test "raises if there are multiple possible matches for given selector and text filter" do
      html = """
      <form id="super-form">
        <button>Save</button>
      </form>

      <form id="other-form">
        <button>Save</button>
      </form>
      """

      msg =
        """
        Found too many "form" elements with nested element with
        selector "button" and text "Save"

        Potential matches:

        <form id="super-form">
          <button>
            Save
          </button>
        </form>

        <form id="other-form">
          <button>
            Save
          </button>
        </form>\n
        """

      assert_raise ArgumentError, msg, fn ->
        Query.find_ancestor!(html, "form", {"button", "Save"})
      end
    end

    test "raises error if cannot find ancestor element (but there are matches)" do
      html = """
      <form id="super-form">
      </form>
      <button>Save</button>
      """

      msg = """
      Could not find "form" for an element with selector "button" and text "Save".

      Found other potential "form":

      <form id="super-form">
      </form>\n
      """

      assert_raise ArgumentError, msg, fn ->
        Query.find_ancestor!(html, "form", {"button", "Save"})
      end
    end

    test "raises error if cannot find ancestor element" do
      html = """
      <button>Save</button>
      """

      msg = """
      Could not find any "form" elements.
      """

      assert_raise ArgumentError, msg, fn ->
        Query.find_ancestor!(html, "form", {"button", "Save"})
      end
    end
  end

  describe "find_ancestor/3" do
    test "finds specified ancestor element of given selector" do
      html = """
      <form id="super-form">
        <input id="greeting" />
      </form>
      """

      {:found, element} = Query.find_ancestor(html, "form", "#greeting")

      assert {"form", [{"id", "super-form"}], _} = element
    end

    test "returns error if cannot find ancestor element" do
      html = """
      <form id="super-form">
      </form>
      <input id="greeting" />
      """

      {:not_found, [other_potential_match]} = Query.find_ancestor(html, "form", "#greeting")

      assert {"form", [{"id", "super-form"}], _} = other_potential_match
    end
  end

  describe "find_ancestor/3 with complex selector + text filter" do
    test "finds specified ancestor element of given selector and text filter" do
      html = """
      <form id="super-form">
        <button>Save</button>
      </form>

      <form id="other-form">
        <button>Reset</button>
      </form>
      """

      {:found, element} = Query.find_ancestor(html, "form", {"button", "Save"})

      assert {"form", [{"id", "super-form"}], _} = element
    end

    test "returns multiple ancestors if many are found (given selector and text filter)" do
      html = """
      <form id="super-form">
        <button>Save</button>
      </form>

      <form id="other-form">
        <button>Save</button>
      </form>
      """

      {:found_many, [el1, el2]} = Query.find_ancestor(html, "form", {"button", "Save"})

      assert {"form", [{"id", "super-form"}], _} = el1
      assert {"form", [{"id", "other-form"}], _} = el2
    end

    test "returns error if cannot find ancestor element" do
      html = """
      <form id="super-form">
      </form>
      """

      {:not_found, [other_potential_match]} =
        Query.find_ancestor(html, "form", {"button", "Save"})

      assert {"form", [{"id", "super-form"}], _} = other_potential_match
    end
  end
end
