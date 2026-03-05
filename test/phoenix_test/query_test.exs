defmodule PhoenixTest.QueryTest do
  use ExUnit.Case, async: true

  import PhoenixTest.TestHelpers

  alias PhoenixTest.Html
  alias PhoenixTest.Locators
  alias PhoenixTest.Query

  describe "find!/2" do
    test "finds element with selector (like find/2)" do
      html = """
      <h1>Hello</h1>
      """

      %LazyHTML{} = element = Query.find!(html, "h1")

      assert {"h1", _, ["Hello"]} = Html.element(element)
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

      %LazyHTML{} = element = Query.find!(html, "h1", "Hello")

      assert {"h1", _, ["Hello"]} = Html.element(element)
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

      assert {"h1", _, ["Hello"]} = Html.element(element)
    end

    test "finds element with an attribute selector" do
      html = """
      <h1 id="title">Hello</h1>
      """

      {:found, element} = Query.find(html, "#title")

      assert {"h1", [{"id", "title"}], ["Hello"]} = Html.element(element)
    end

    test "finds elements if multiple match selector" do
      html = """
      <div class="greeting">Hello</div>
      <div class="greeting">Hi</div>
      """

      {:found_many, %LazyHTML{} = elements} = Query.find(html, ".greeting")

      assert [
               {"div", [{"class", "greeting"}], ["Hello"]},
               {"div", [{"class", "greeting"}], ["Hi"]}
             ] = LazyHTML.to_tree(elements)
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

      assert {"h1", _, ["Hello"]} = Html.element(element)
    end

    test "ignores element's extra whitespace" do
      html = """
      <h1>Hello       </h1>
      """

      {:found, element} = Query.find(html, "h1", "Hello")

      assert {"h1", _, ["Hello       "]} = Html.element(element)
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

      assert {"h1", [{"id", "title"}], ["Hello"]} = Html.element(element)
    end

    test "finds elements if multiple match selector AND text" do
      html = """
      <div class="greeting">Hello</div>
      <div class="greeting">Hello</div>
      """

      {:found_many, [el1, el2]} = Query.find(html, ".greeting", "Hello")

      assert {"div", [{"class", "greeting"}], ["Hello"]} = Html.element(el1)
      assert {"div", [{"class", "greeting"}], ["Hello"]} = Html.element(el2)
    end

    test "only returns element `at` (1-based index) if requested" do
      html = """
      <div id="1" class="greeting">Hello</div>
      <div id="2" class="greeting">Hello</div>
      """

      {:found, element} = Query.find(html, ".greeting", "Hello", at: 2)

      assert {"div", [{"id", "2"}, _], ["Hello"]} = Html.element(element)
    end

    test "finds element with text if multiple match CSS selector" do
      html = """
      <div class="greeting">Hello</div>
      <div class="greeting">Hi</div>
      """

      {:found, element} = Query.find(html, ".greeting", "Hello")

      assert {"div", [{"class", "greeting"}], ["Hello"]} = Html.element(element)
    end

    test "returns :not_found if selector and text don't match an element" do
      html = """
      <h1 id="title">Hello</h1>
      """

      assert {:not_found, %LazyHTML{} = elements} = Query.find(html, ".no-value", "no value")
      assert Enum.empty?(elements)
    end

    test "returns :not_found with elements that matched selector but not text (if any)" do
      html = """
      <h1 id="title">Hello</h1>
      """

      assert {:not_found, %LazyHTML{} = element} = Query.find(html, "h1", "no value")
      assert {"h1", [{"id", "title"}], ["Hello"]} = Html.element(element)
    end
  end

  describe "find_by_role!/2" do
    test "finds an element based on locator's roles" do
      html = """
      <button id="title">Hello</button>
      """

      locator = Locators.button(text: "Hello")

      element = Query.find_by_role!(html, locator)

      assert {"button", _, ["Hello"]} = Html.element(element)
    end

    test "raises an error if there's no match" do
      html = """
      <button id="title">Hello</button>
      """

      locator = Locators.button(text: "Hi")

      assert_raise ArgumentError, ~r/Could not find an element/, fn ->
        Query.find_by_role!(html, locator)
      end
    end

    test "raises an error if there's more than one match" do
      html = """
      <button id="title">Hello</button>
      <input type="submit" value="Hello" />
      """

      locator = Locators.button(text: "Hello")

      assert_raise ArgumentError, ~r/too many matches/, fn ->
        Query.find_by_role!(html, locator)
      end
    end
  end

  describe "find_one_of!/2" do
    test "returns element when one matches" do
      html = """
      <h1 id="title">Hello</h1>
      <h2 id="subtitle">Not found</h2>
      """

      element = Query.find_one_of!(html, [{"h1", "Hello"}, {"h2", "Hi"}])

      assert {"h1", _, ["Hello"]} = Html.element(element)
    end

    test "raises error if multiple match" do
      html = """
      <h2>Hello</h2>
      <h2>Greetings</h2>
      """

      assert_raise ArgumentError, ~r/too many matches/, fn ->
        Query.find_one_of!(html, ["h2"])
      end
    end

    test "raises an error when element could not be found" do
      html = """
      <h1>Hello</h1>
      """

      msg = ~r/Could not find an element with given selectors./

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
        ignore_whitespace("""
        Could not find an element with given selectors.

        I was looking for an element with one of these selectors:

        - "h2" with content "Hi"
        - "h3"

        I found some elements that match the selector but not the content:

        <h2>Hello</h2>
        <h2>Greetings</h2>
        """)

      assert_raise ArgumentError, msg, fn ->
        Query.find_one_of!(html, [{"h2", "Hi"}, "h3"])
      end
    end
  end

  describe "find_one_of/2" do
    test "finds one of elements that match passed selectors" do
      html = """
      <h1 id="title">Hello</h1>
      <h2 id="subtitle">Not found</h2>
      """

      {:found, element} = Query.find_one_of(html, [{"h1", "Hello"}, {"h2", "Hi"}])

      assert {"h1", _, ["Hello"]} = Html.element(element)
    end

    test "finds elements with selector or selector and text" do
      html = """
      <h1 id="title">Hello</h1>
      <h2 id="subtitle">Hi</h2>
      """

      assert {:found, _element} = Query.find_one_of(html, [{"h1", "Hello"}])
      assert {:found, element} = Query.find_one_of(html, ["h1"])
      assert {"h1", [{"id", "title"}], ["Hello"]} = Html.element(element)
    end

    test "returns {:found_many, found} when several match" do
      html = """
      <h1 id="title">Hello</h1>
      <h2 id="subtitle">Hi</h2>
      <h2 id="another">Hi again</h2>
      """

      {:found_many, [elem1, elem2, elem3]} =
        Query.find_one_of(html, [{"h1", "Hello"}, {"h2", "Hi"}])

      assert {"h1", _, ["Hello"]} = Html.element(elem1)
      assert {"h2", _, ["Hi"]} = Html.element(elem2)
      assert {"h2", _, ["Hi again"]} = Html.element(elem3)
    end

    test "returns :not_found when no selector matches" do
      html = """
      <h2>Hello</h2>
      <h2>Greetings</h2>
      """

      assert {:not_found, []} = Query.find_one_of(html, ["h1"])

      assert {:not_found, matched_selector_but_not_text} =
               Query.find_one_of(html, [{"h2", "Hi"}])

      [a, b] = LazyHTML.to_tree(matched_selector_but_not_text)
      assert {"h2", _, ["Hello"]} = a
      assert {"h2", _, ["Greetings"]} = b
    end
  end

  describe "find_by_label!/3" do
    test "raises error if no label is found" do
      html = """
      <input id="name"/>
      """

      msg = """
      Could not find element with label "Name"
      """

      assert_raise ArgumentError, msg, fn ->
        Query.find_by_label!(html, "input", "Name")
      end
    end

    test "raises if label isn't found (but other labels are present)" do
      html = """
      <label for="name">Names</label>
      """

      assert_raise ArgumentError, ~r/Could not find element with label "Email"/, fn ->
        Query.find_by_label!(html, "input", "Email")
      end
    end

    test "raises error if label doesn't have a `for` attribute" do
      html = """
      <label>Name</label>
      """

      assert_raise ArgumentError, ~r/Found label, but it doesn't have `for` attribute/, fn ->
        Query.find_by_label!(html, "input", "Name")
      end
    end

    test "raises error if label's `for` doesn't have corresponding `id`" do
      html = """
      <label for="name">Name</label>
      <input type="text" name="name" />
      """

      assert_raise ArgumentError, ~r/but can't find labeled element whose `id` matches label's `for` attribute/, fn ->
        Query.find_by_label!(html, "input", "Name")
      end
    end

    test "raises error if multiple labels match" do
      html = """
      <label for="greeting">Hello</label>
      <label for="second_greeting">Hello</label>
      """

      msg = ~r/Found many labels with text "Hello"/

      assert_raise ArgumentError, msg, fn ->
        Query.find_by_label!(html, "input", "Hello")
      end
    end

    test "raises error if multiple labels and inputs match" do
      html = """
      <label for="greeting">Hello</label>
      <input id="greeting" />
      <label for="second_greeting">Hello</label>
      <input id="second_greeting" />
      """

      msg = ~r/Found many elements with label "Hello" and matching the provided selectors/

      assert_raise ArgumentError, msg, fn ->
        Query.find_by_label!(html, "input", "Hello")
      end
    end

    test "raises error if multiple labels and inputs match (one explicit, one implicit)" do
      html = """
      <label for="greeting">Hello</label>
      <input id="greeting" />

      <label>Hello <input id="second_greeting" /></label>
      """

      msg = ~r/Found many elements with label "Hello" and matching the provided selectors/

      assert_raise ArgumentError, msg, fn ->
        Query.find_by_label!(html, "input", "Hello")
      end
    end

    test "raises error if label has for attribute and nested input" do
      html = """
      <label for="other_greeting">Hello <input /></label>
      <input id="other_greeting" />
      """

      msg = ~r/Found a label which references two different inputs/

      assert_raise ArgumentError, msg, fn ->
        Query.find_by_label!(html, "input", "Hello")
      end
    end

    test "returns found element" do
      html = """
      <label for="greeting">Hello</label>
      <input id="greeting"/>
      """

      element = Query.find_by_label!(html, "input", "Hello")

      assert {"input", [{"id", "greeting"}], []} = Html.element(element)
    end

    test "returns found element label points to (even if id has ? character)" do
      html = """
      <label for="greeting?">Hello</label>
      <input id="greeting?"/>
      """

      element = Query.find_by_label!(html, "input", "Hello")

      assert {"input", [{"id", "greeting?"}], []} = Html.element(element)
    end

    test "returns found element when association is implicit" do
      html = """
      <label>
        Hello
        <input name="greeting" />
      </label>
      """

      element = Query.find_by_label!(html, "input", "Hello")

      assert {"input", [{"name", "greeting"}], []} = Html.element(element)
    end

    test "can filter labels based on associated input's selector" do
      html = """
      <input id="greeting" value="greeting" name="greeting" />
      <label for="greeting">Hello</label>

      <input id="second_greeting" value="second_greeting" name="second_greeting"/>
      <label for="second_greeting">Hello</label>
      """

      element = Query.find_by_label!(html, "#greeting", "Hello")

      assert {"input", [{"id", "greeting"} | _], []} = Html.element(element)
    end

    test "raises error if label's for doesn't have matching element with id" do
      html = """
      <label for="name">Name</label>
      <input id="not-name" type="text" name="name" />
      """

      assert_raise ArgumentError,
                   ~r/Found label but can't find labeled element whose `id` matches label's `for` attribute./,
                   fn ->
                     Query.find_by_label!(html, "#not-name", "Name")
                   end
    end

    test "raises error if label matches element with id but not the provided selector" do
      html = """
      <label for="name">Name</label>
      <input id="not-name" type="text" name="name" />
      """

      assert_raise ArgumentError,
                   ~r/Found label but can't find labeled element whose `id` matches label's `for` attribute/,
                   fn ->
                     Query.find_by_label!(html, "input[id='not-name']", "Name")
                   end
    end

    test "raises error if label matches element with provided selector but input doesn't have matching id" do
      html = """
      <label for="greeting">Hello</label>
      <input name="greeting"/>
      """

      assert_raise ArgumentError, ~r/can't find labeled element whose `id` matches/, fn ->
        Query.find_by_label!(html, "input[name='greeting']", "Hello")
      end
    end

    test "raises error if label with element and implicit association but input selector doesn't match" do
      html = """
      <label>
        Hello
        <input name="greeting" />
      </label>
      """

      assert_raise ArgumentError, ~r/Found label, but it doesn't have `for` attribute/, fn ->
        Query.find_by_label!(html, "input[name='not-greeting']", "Hello")
      end
    end
  end

  describe "find_by_label/3" do
    test "returns :no_label error if label isn't found" do
      html = """
      <input id="name"/>
      """

      assert {:not_found, :no_label, %LazyHTML{} = element} = Query.find_by_label(html, "input", "Name")

      assert Enum.empty?(element)
    end

    test "returns :no_label error with other labels present if some are found" do
      html = """
      <label for="name">Names</label>
      """

      assert {:not_found, :no_label, labels} = Query.find_by_label(html, "input", "Email")
      assert {"label", [{"for", "name"}], ["Names"]} = Html.element(labels)
    end

    test "returns :missing_for error if label doesn't have a `for` attribute" do
      html = """
      <label>Name</label>
      """

      assert {:not_found, :missing_for, label} = Query.find_by_label(html, "input", "Name")
      assert {"label", [], ["Name"]} = Html.element(label)
    end

    test "raises :missing_for error if label with element and implicit association but input selector doesn't match" do
      html = """
      <label>
        Hello
        <input name="greeting" />
      </label>
      """

      assert {:not_found, :missing_for, label} = Query.find_by_label(html, "input[name='not-greeting']", "Hello")
      assert {"label", [], _} = Html.element(label)
    end

    test "returns :missing_input error if label's `for` doesn't have corresponding `id`" do
      html = """
      <label for="name">Name</label>
      <input type="text" name="name" />
      """

      assert {:not_found, :missing_input, label} = Query.find_by_label(html, "input", "Name")
      assert {"label", [{"for", "name"}], ["Name"]} = Html.element(label)
    end

    test "returns :missing_input error if label's `for` doesn't have matching element with same id" do
      html = """
      <label for="name">Name</label>
      <input id="not-name" type="text" name="name" />
      """

      assert {:not_found, :missing_input, label} = Query.find_by_label(html, "#not-name", "Name")
      assert {"label", _, ["Name"]} = Html.element(label)
    end

    test "returns :found_many_labels error if multiple labels match" do
      html = """
      <label for="greeting">Hello</label>
      <label for="second_greeting">Hello</label>
      """

      assert {:not_found, :found_many_labels, labels} = Query.find_by_label(html, "input", "Hello")
      assert length(labels) == 2
      assert {"label", _, ["Hello"]} = labels |> hd() |> Html.element()
    end

    test "returns :found_many_labels_with_inputs error if multiple labels and inputs match" do
      html = """
      <label for="greeting">Hello</label>
      <input id="greeting" />
      <label for="second_greeting">Hello</label>
      <input id="second_greeting" />
      """

      assert {:not_found, :found_many_labels_with_inputs, labels, inputs} = Query.find_by_label(html, "input", "Hello")
      assert length(labels) == 2
      assert {"label", _, ["Hello"]} = labels |> hd() |> Html.element()
      assert length(inputs) == 2
      assert {"input", _, []} = inputs |> hd() |> Html.element()
    end

    test "returns :found_many_labels_with_inputs error if multiple labels and inputs match (one explicit, one implicit)" do
      html = """
      <label for="greeting">Hello</label>
      <input id="greeting" />

      <label>Hello <input id="second_greeting" /></label>
      """

      assert {:not_found, :found_many_labels_with_inputs, labels, inputs} = Query.find_by_label(html, "input", "Hello")
      assert length(labels) == 2
      assert {"label", _, ["Hello"]} = labels |> hd() |> Html.element()
      assert length(inputs) == 2
      assert {"input", _, []} = inputs |> hd() |> Html.element()
    end

    test "raises error if label has for attribute and nested input" do
      html = """
      <label for="other_greeting">Hello <input /></label>
      <input id="other_greeting" />
      """

      msg = ~r/Found a label which references two different inputs/

      assert_raise ArgumentError, msg, fn ->
        Query.find_by_label(html, "input", "Hello")
      end
    end

    test "returns {:found, element} when input is found" do
      html = """
      <label for="greeting">Hello</label>
      <input id="greeting"/>
      """

      assert {:found, element} = Query.find_by_label(html, "input", "Hello")
      assert {"input", [{"id", "greeting"}], []} = Html.element(element)
    end

    test "returns {:found, element} even if id has ? character" do
      html = """
      <label for="greeting?">Hello</label>
      <input id="greeting?"/>
      """

      assert {:found, element} = Query.find_by_label(html, "input", "Hello")
      assert {"input", [{"id", "greeting?"}], []} = Html.element(element)
    end

    test "returns {:found, element} when association is implicit" do
      html = """
      <label>
        Hello
        <input name="greeting" />
      </label>
      """

      assert {:found, element} = Query.find_by_label(html, "input", "Hello")
      assert {"input", [{"name", "greeting"}], []} = Html.element(element)
    end

    test "can filter labels based on associated input's selector" do
      html = """
      <input id="greeting" value="greeting" name="greeting" />
      <label for="greeting">Hello</label>

      <input id="second_greeting" value="second_greeting" name="second_greeting"/>
      <label for="second_greeting">Hello</label>
      """

      {:found, element} = Query.find_by_label(html, "#greeting", "Hello")

      assert {"input", [{"id", "greeting"} | _], []} = Html.element(element)
    end

    test "can filter labels wrapping a pre-filled textarea" do
      html = """
      <label for="wrapped-notes">
        Wrapped notes <textarea name="wrapped-notes" rows="5" cols="33">
          Prefilled wrapped notes
        </textarea>
      </label>
      """

      {:found, element} = Query.find_by_label(html, "label", "Wrapped notes")

      assert {"label", [{"for", "wrapped-notes"}], _} = Html.element(element)
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

      assert {"form", [{"id", "super-form"}], _} = Html.element(element)
    end

    test "accepts descendant maps with selector metadata" do
      html = """
      <form id="super-form">
        <input id="greeting" />
      </form>
      """

      element = Query.find_ancestor!(html, "form", %{selector: "#greeting"})

      assert {"form", [{"id", "super-form"}], _} = Html.element(element)
    end

    test "raises error if it finds too many ancestor element that match selector" do
      html = """
      <form id="form-1">
        <input type="text" name="email" />
      </form>
      <form id="form-2">
        <input type="text" name="email" />
      </form>
      """

      msg = """
      Found too many "form" matches for element with selector "input[type='text'][name='email']"

      Please make the selector more specific (e.g. using an id)

      The following "form" elements were found:

      <form id="form-1">
        <input type="text" name="email"/>
      </form>
      <form id="form-2">
        <input type="text" name="email"/>
      </form>
      """

      assert_raise ArgumentError, msg, fn ->
        Query.find_ancestor!(html, "form", "input[type='text'][name='email']")
      end
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
      </form>
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

      assert {"form", [{"id", "super-form"}], _} = Html.element(element)
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
          <button>Save</button>
        </form>
        <form id="other-form">
          <button>Save</button>
        </form>
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
      </form>
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

      assert {"form", [{"id", "super-form"}], _} = Html.element(element)
    end

    test "returns error if cannot find ancestor element" do
      html = """
      <form id="super-form">
      </form>
      <input id="greeting" />
      """

      {:not_found, [element]} = Query.find_ancestor(html, "form", "#greeting")

      assert {"form", [{"id", "super-form"}], _} = Html.element(element)
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

      assert {"form", [{"id", "super-form"}], _} = Html.element(element)
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

      assert {"form", [{"id", "super-form"}], _} = Html.element(el1)
      assert {"form", [{"id", "other-form"}], _} = Html.element(el2)
    end

    test "returns error if cannot find ancestor element" do
      html = """
      <form id="super-form">
      </form>
      """

      {:not_found, [element]} = Query.find_ancestor(html, "form", {"button", "Save"})
      assert {"form", [{"id", "super-form"}], _} = Html.element(element)
    end
  end

  describe "has_ancestor?/3" do
    test "returns true when descendant has matching ancestor" do
      html = """
      <form id="super-form">
        <input id="greeting" />
      </form>
      """

      assert Query.has_ancestor?(html, "form", "#greeting")
    end

    test "returns false when descendant has no matching ancestor" do
      html = """
      <form id="super-form">
      </form>
      <input id="greeting" />
      """

      refute Query.has_ancestor?(html, "form", "#greeting")
    end

    test "works with {selector, text} descendant" do
      html = """
      <form id="super-form">
        <button>Save</button>
      </form>

      <form id="other-form">
        <button>Reset</button>
      </form>
      """

      assert Query.has_ancestor?(html, "form", {"button", "Save"})
      refute Query.has_ancestor?(html, "form", {"button", "Delete"})
    end
  end
end
