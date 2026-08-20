defmodule PhoenixTest.QueryTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.Html
  alias PhoenixTest.Locators
  alias PhoenixTest.Query
  alias PhoenixTest.Query.Failure

  describe "find" do
    test "finds an element by tag" do
      assert {:ok, element} = Query.find("<h1>Hello</h1>", "h1")
      assert {"h1", _, ["Hello"]} = Html.element(element)
    end

    test "finds an element by attribute selector" do
      assert {:ok, element} = Query.find("<h1 id=\"title\">Hello</h1>", "#title")
      assert {"h1", [{"id", "title"}], ["Hello"]} = Html.element(element)
    end

    test "reports all selector matches" do
      assert {:error, %Failure{kind: :multiple_matches, candidates: elements}} =
               Query.find("<div class=greeting>Hello</div><div class=greeting>Hi</div>", ".greeting")

      assert [{"div", _, ["Hello"]}, {"div", _, ["Hi"]}] = Enum.map(elements, &Html.element/1)
    end

    test "reports a missing selector" do
      assert {:error, %Failure{kind: :not_found, operation: :find, request: %{selector: ".missing"}, candidates: []}} =
               Query.find("<h1>Hello</h1>", ".missing")
    end

    test "finds text" do
      assert {:ok, element} = Query.find("<h1>Hello</h1>", "h1", "Hello")
      assert {"h1", _, ["Hello"]} = Html.element(element)
    end

    test "matches text with trailing whitespace" do
      assert {:ok, element} = Query.find("<h1>Hello       </h1>", "h1", "Hello")
      assert {"h1", _, ["Hello       "]} = Html.element(element)
    end

    test "uses substring matching unless exact is requested" do
      assert {:ok, _} = Query.find("<h1>Hello world</h1>", "h1", "Hello")
      assert {:error, %Failure{kind: :not_found}} = Query.find("<h1>Hello world</h1>", "h1", "Hello", exact: true)
    end

    test "finds attribute selector and text" do
      assert {:ok, element} = Query.find("<h1 id=\"title\">Hello</h1>", "#title", "Hello")
      assert {"h1", [{"id", "title"}], ["Hello"]} = Html.element(element)
    end

    test "reports multiple text matches" do
      assert {:error, %Failure{kind: :multiple_matches, candidates: [one, two]}} =
               Query.find("<div class=greeting>Hello</div><div class=greeting>Hello</div>", ".greeting", "Hello")

      assert {"div", _, ["Hello"]} = Html.element(one)
      assert {"div", _, ["Hello"]} = Html.element(two)
    end

    test "uses one-based position" do
      html = "<div id=\"1\" class=greeting>Hello</div><div id=\"2\" class=greeting>Hello</div>"
      assert {:ok, element} = Query.find(html, ".greeting", "Hello", at: 2)
      assert {"div", [{"id", "2"} | _], ["Hello"]} = Html.element(element)
    end

    test "position can make a multiple selector match unique" do
      assert {:ok, element} = Query.find("<p>one</p><p>two</p>", "p", at: 1)
      assert {"p", _, ["one"]} = Html.element(element)
    end

    test "selects text from several CSS candidates" do
      assert {:ok, element} =
               Query.find("<div class=greeting>Hello</div><div class=greeting>Hi</div>", ".greeting", "Hello")

      assert {"div", _, ["Hello"]} = Html.element(element)
    end

    test "retains no candidates when selector and text both miss" do
      assert {:error, %Failure{kind: :not_found, candidates: candidates}} =
               Query.find("<h1>Hello</h1>", ".missing", "no value")

      assert Enum.empty?(candidates)
    end

    test "retains selector candidates when text misses" do
      assert {:error, %Failure{kind: :not_found, request: %{selector: "h1", text: "no value"}, candidates: candidates}} =
               Query.find("<h1 id=title>Hello</h1>", "h1", "no value")

      assert {"h1", [{"id", "title"}], ["Hello"]} = Html.element(candidates)
    end

    test "applies position before matching text" do
      assert {:error, %Failure{kind: :not_found, candidates: candidates}} =
               Query.find("<p>one</p><p>two</p>", "p", "two", at: 1)

      assert [{"p", _, ["one"]}, {"p", _, ["two"]}] = LazyHTML.to_tree(candidates)
    end

    test "reports a position beyond the selector matches" do
      assert {:error, %Failure{kind: :not_found, candidates: candidates}} =
               Query.find("<p>one</p>", "p", at: 2)

      assert Enum.empty?(candidates)
    end

    test "uses exact text matching with a selector position" do
      assert {:ok, element} = Query.find("<p>one</p><p>one!</p>", "p", "one", exact: true, at: 1)
      assert {"p", _, ["one"]} = Html.element(element)
    end
  end

  describe "find_first and selected" do
    test "find_first returns the first selector match" do
      assert {:ok, element} = Query.find_first("<p>one</p><p>two</p>", "p")
      assert {"p", _, ["one"]} = Html.element(element)
    end

    test "find_first reports a missing selector" do
      assert {:error, %Failure{kind: :not_found, operation: :find, request: %{selector: "p"}}} =
               Query.find_first("<div></div>", "p")
    end

    test "find_first filters by text" do
      assert {:ok, element} = Query.find_first("<p>one</p><p>two</p>", "p", "two")
      assert {"p", _, ["two"]} = Html.element(element)
    end

    test "find_first retains candidates when text misses" do
      assert {:error, %Failure{kind: :not_found, operation: :find_first, candidates: candidates}} =
               Query.find_first("<p>one</p>", "p", "two")

      assert [{"p", _, ["one"]}] = LazyHTML.to_tree(candidates)
    end

    test "finds select by selected option text" do
      assert {:ok, element} = Query.find_by_selected("<select><option selected>One</option></select>", "select", "One")
      assert {"select", _, _} = Html.element(element)
    end

    test "reports selected candidates that do not match" do
      assert {:error, %Failure{kind: :not_found, operation: :find_by_selected, candidates: candidates}} =
               Query.find_by_selected("<select><option selected>One</option></select>", "select", "Two")

      assert {"select", _, _} = Html.element(candidates)
    end

    test "uses position when finding selected options" do
      html = "<select><option selected>One</option></select><select><option selected>Two</option></select>"
      assert {:ok, element} = Query.find_by_selected(html, "select", "Two", at: 2)
      assert {"select", _, _} = Html.element(element)
    end

    test "reports multiple selected matches" do
      html = "<select><option selected>One</option></select><select><option selected>One</option></select>"

      assert {:error, %Failure{kind: :multiple_matches, candidates: [_, _]}} =
               Query.find_by_selected(html, "select", "One")
    end

    test "does not treat a non-default option as selected" do
      assert {:error, %Failure{kind: :not_found}} =
               Query.find_by_selected("<select><option>One</option><option>Two</option></select>", "select", "Two")
    end

    test "finds a labelled select by selected option" do
      html = "<label for=role>Role</label><select id=role><option selected>Admin</option></select>"
      assert {:ok, _} = Query.find_by_label_and_selected(html, "select", "Role", "Admin")
    end

    test "labelled selected lookup preserves label failures" do
      assert {:error,
              %Failure{
                kind: :no_label,
                operation: :find_by_label_and_selected,
                request: %{label: "Role", selected: "Admin"}
              }} =
               Query.find_by_label_and_selected("<select></select>", "select", "Role", "Admin")
    end
  end

  describe "find_one_of" do
    test "finds one selector and text pair" do
      assert {:ok, element} = Query.find_one_of("<h1 id=title>Hello</h1><h2>Other</h2>", [{"h1", "Hello"}, {"h2", "Hi"}])
      assert {"h1", [{"id", "title"}], ["Hello"]} = Html.element(element)
    end

    test "accepts bare selectors" do
      assert {:ok, element} = Query.find_one_of("<h1 id=title>Hello</h1>", ["h1"])
      assert {"h1", [{"id", "title"}], ["Hello"]} = Html.element(element)
    end

    test "reports all matches across selectors" do
      assert {:error, %Failure{kind: :multiple_matches, candidates: [one, two, three]}} =
               Query.find_one_of("<h1>Hello</h1><h2>Hi</h2><h2>Hi again</h2>", [{"h1", "Hello"}, {"h2", "Hi"}])

      assert {"h1", _, _} = Html.element(one)
      assert {"h2", _, _} = Html.element(two)
      assert {"h2", _, _} = Html.element(three)
    end

    test "retains potential text candidates" do
      assert {:error,
              %Failure{
                kind: :not_found,
                request: %{selectors: [{"h2", "Hi"}]},
                candidates: candidates,
                details: %{results: _}
              }} =
               Query.find_one_of("<h2>Hello</h2><h2>Greetings</h2>", [{"h2", "Hi"}])

      assert [{"h2", _, ["Hello"]}, {"h2", _, ["Greetings"]}] = candidates |> hd() |> LazyHTML.to_tree()
    end

    test "reports no candidates when no selector matches" do
      assert {:error, %Failure{kind: :not_found, candidates: candidates, details: %{results: results}}} =
               Query.find_one_of("<h1>Hello</h1>", ["h2", {"h3", "Hello"}])

      assert [candidate] = candidates
      assert Enum.empty?(candidate)
      assert Enum.all?(results, &match?({:error, %Failure{kind: :not_found}}, &1))
    end

    test "combines a bare selector with a selector and text pair" do
      assert {:ok, element} = Query.find_one_of("<h1>Hello</h1><h2>Two</h2>", ["h1", {"h2", "Three"}])
      assert {"h1", _, ["Hello"]} = Html.element(element)
    end

    test "reports matches from duplicate selector entries" do
      assert {:error, %Failure{kind: :multiple_matches, candidates: [one, two]}} =
               Query.find_one_of("<h1>Hello</h1>", ["h1", "h1"])

      assert {"h1", _, ["Hello"]} = Html.element(one)
      assert {"h1", _, ["Hello"]} = Html.element(two)
    end
  end

  describe "find_by_role" do
    test "role lookup finds a button" do
      locator = Locators.button(text: "Hello")
      assert {:ok, element} = Query.find_by_role("<button id=title>Hello</button>", locator)
      assert {"button", _, ["Hello"]} = Html.element(element)
    end

    test "role lookup reports no match as structured failure" do
      locator = Locators.button(text: "Hi")

      assert {:error,
              %Failure{
                kind: :not_found,
                operation: :find_by_role,
                request: %{locator: ^locator, role_selectors: _},
                details: %{label_failure: %Failure{}}
              }} =
               Query.find_by_role("<button>Hello</button>", locator)
    end

    test "role lookup reports multiple matches" do
      locator = Locators.button(text: "Hello")

      assert {:error, %Failure{kind: :multiple_matches, operation: :find_by_role, candidates: [_, _]}} =
               Query.find_by_role("<button>Hello</button><input type=submit value=Hello>", locator)
    end

    test "role lookup falls back to an associated label" do
      locator = Locators.button(text: "Save")
      assert {:ok, element} = Query.find_by_role("<label for=save>Save</label><input id=save type=submit>", locator)
      assert {"input", _, []} = Html.element(element)
    end
  end

  describe "find_by_label" do
    test "reports no label" do
      assert {:error,
              %Failure{
                kind: :no_label,
                labels: [],
                candidates: candidates,
                request: %{label: "Name", input_selectors: ["input"]}
              }} =
               Query.find_by_label("<input id=name>", "input", "Name")

      assert Enum.empty?(candidates)
    end

    test "retains other labels when requested label is absent" do
      assert {:error, %Failure{kind: :no_label, candidates: candidates}} =
               Query.find_by_label("<label for=name>Names</label>", "input", "Email")

      assert {"label", [{"for", "name"}], ["Names"]} = Html.element(candidates)
    end

    test "reports a label without for" do
      assert {:error, %Failure{kind: :missing_label_for, labels: [label]}} =
               Query.find_by_label("<label>Name</label>", "input", "Name")

      assert {"label", [], ["Name"]} = Html.element(label)
    end

    test "reports an implicit label whose input misses selector" do
      html = "<label>Hello <input name=greeting></label>"

      assert {:error, %Failure{kind: :missing_label_for, labels: [_]}} =
               Query.find_by_label(html, "input[name='not-greeting']", "Hello")
    end

    test "reports missing explicitly labelled input" do
      html = "<label for=name>Name</label><input name=name>"

      assert {:error, %Failure{kind: :missing_labeled_input, labels: [label], details: %{for: "name"}}} =
               Query.find_by_label(html, "input", "Name")

      assert {"label", _, _} = Html.element(label)
    end

    test "reports mismatched selector result for explicit label" do
      html = "<label for=name>Name</label><input id=not-name name=name>"

      assert {:error, %Failure{kind: :missing_labeled_input, labels: [_], details: %{for: "name"}}} =
               Query.find_by_label(html, "#not-name", "Name")
    end

    test "reports many matching labels without inputs" do
      html = "<label for=one>Hello</label><label for=two>Hello</label>"
      assert {:error, %Failure{kind: :multiple_labels, labels: [_, _]}} = Query.find_by_label(html, "input", "Hello")
    end

    test "reports many labels and inputs" do
      html = "<label for=one>Hello</label><input id=one><label for=two>Hello</label><input id=two>"

      assert {:error, %Failure{kind: :multiple_matches, labels: [_, _], inputs: [_, _]}} =
               Query.find_by_label(html, "input", "Hello")
    end

    test "reports explicit and implicit multiple label associations" do
      html = "<label for=one>Hello</label><input id=one><label>Hello <input id=two></label>"

      assert {:error, %Failure{kind: :multiple_matches, labels: [_, _], inputs: [_, _]}} =
               Query.find_by_label(html, "input", "Hello")
    end

    test "reports conflicting explicit and implicit associations" do
      html = "<label for=other>Hello <input id=nested></label><input id=other>"

      assert {:error, %Failure{kind: :conflicting_label_associations, labels: [_], inputs: [_, _]}} =
               Query.find_by_label(html, "input", "Hello")
    end

    test "finds an explicitly associated input" do
      assert {:ok, element} =
               Query.find_by_label("<label for=greeting>Hello</label><input id=greeting>", "input", "Hello")

      assert {"input", [{"id", "greeting"}], []} = Html.element(element)
    end

    test "finds an id containing question mark" do
      assert {:ok, element} =
               Query.find_by_label("<label for=\"greeting?\">Hello</label><input id=\"greeting?\">", "input", "Hello")

      assert {"input", [{"id", "greeting?"}], []} = Html.element(element)
    end

    test "finds an implicitly associated input" do
      assert {:ok, element} = Query.find_by_label("<label>Hello <input name=greeting></label>", "input", "Hello")
      assert {"input", [{"name", "greeting"}], []} = Html.element(element)
    end

    test "filters labels by the associated input selector" do
      html = "<input id=greeting><label for=greeting>Hello</label><input id=second><label for=second>Hello</label>"
      assert {:ok, element} = Query.find_by_label(html, "#greeting", "Hello")
      assert {"input", [{"id", "greeting"}], []} = Html.element(element)
    end

    test "can find a label wrapping a prefilled textarea" do
      html = "<label for=notes>Wrapped notes <textarea name=notes>Prefilled wrapped notes</textarea></label>"
      assert {:ok, element} = Query.find_by_label(html, "label", "Wrapped notes")
      assert {"label", [{"for", "notes"}], _} = Html.element(element)
    end

    test "finds aria-label" do
      assert {:ok, element} = Query.find_by_label("<input name=search aria-label=Search>", "input", "Search")
      assert {"input", [{"name", "search"}, {"aria-label", "Search"}], []} = Html.element(element)
    end

    test "finds aria-labelledby" do
      html = "<span id=search-label>Search</span><input name=search aria-labelledby=search-label>"
      assert {:ok, element} = Query.find_by_label(html, "input", "Search")
      assert {"input", [{"name", "search"}, {"aria-labelledby", "search-label"}], []} = Html.element(element)
    end

    test "finds aria-labelledby composed from multiple ids" do
      html = "<span id=one>Middle</span><span id=two>Earth</span><input name=realm aria-labelledby=\"one two\">"
      assert {:ok, element} = Query.find_by_label(html, "input", "Middle Earth")
      assert {"input", [{"name", "realm"}, {"aria-labelledby", "one two"}], []} = Html.element(element)
    end

    test "aria matching honors exact" do
      html = "<input aria-label=\"Search the archives\">"
      assert {:ok, _} = Query.find_by_label(html, "input", "Search", exact: false)
      assert {:error, %Failure{kind: :no_label}} = Query.find_by_label(html, "input", "Search", exact: true)
    end

    test "aria matching normalizes whitespace" do
      assert {:ok, _} =
               Query.find_by_label("<input aria-label=\"  Search   the archives  \">", "input", "Search the archives",
                 exact: true
               )
    end

    test "prefers html label association over aria label" do
      html = "<label for=labelled>Search</label><input id=labelled name=labelled><input name=aria aria-label=Search>"
      assert {:ok, element} = Query.find_by_label(html, "input", "Search")
      assert {"input", [{"id", "labelled"}, {"name", "labelled"}], []} = Html.element(element)
    end

    test "preserves the label failure when aria misses" do
      assert {:error, %Failure{kind: :no_label}} =
               Query.find_by_label("<input aria-label=\"Something else\">", "input", "Search")
    end

    test "reports multiple aria matches as inputs" do
      html = "<input name=one aria-label=Search><input name=two aria-label=Search>"

      assert {:error, %Failure{kind: :multiple_matches, labels: [], inputs: [_, _]}} =
               Query.find_by_label(html, "input", "Search")
    end

    test "accepts multiple input selectors" do
      html = "<label for=message>Message</label><textarea id=message></textarea>"
      assert {:ok, element} = Query.find_by_label(html, ["input", "textarea"], "Message")
      assert {"textarea", [{"id", "message"}], []} = Html.element(element)
    end

    test "uses exact matching for html labels by default" do
      assert {:error, %Failure{kind: :no_label}} =
               Query.find_by_label("<label for=name>Full name</label><input id=name>", "input", "name")
    end

    test "can use substring matching for html labels" do
      assert {:ok, element} =
               Query.find_by_label("<label for=name>Full name</label><input id=name>", "input", "name", exact: false)

      assert {"input", [{"id", "name"}], []} = Html.element(element)
    end

    test "reports duplicate explicitly associated inputs" do
      html = "<label for=name>Name</label><input id=name><input id=name>"

      assert {:error, %Failure{kind: :missing_labeled_input, labels: [_], candidates: candidates}} =
               Query.find_by_label(html, "input", "Name")

      assert [{"input", [{"id", "name"}], []}, {"input", [{"id", "name"}], []}] = Enum.map(candidates, &Html.element/1)
    end
  end

  describe "ancestors" do
    test "finds ancestor by descendant selector" do
      assert {:ok, element} = Query.find_ancestor("<form id=super><input id=greeting></form>", "form", "#greeting")
      assert {"form", [{"id", "super"}], _} = Html.element(element)
    end

    test "accepts descendant selector map" do
      assert {:ok, element} =
               Query.find_ancestor("<form id=super><input id=greeting></form>", "form", %{selector: "#greeting"})

      assert {"form", [{"id", "super"}], _} = Html.element(element)
    end

    test "accepts descendant id map" do
      assert {:ok, _} = Query.find_ancestor("<form><input id=greeting></form>", "form", %{id: "greeting"})
    end

    test "reports multiple matching ancestors" do
      html = "<form id=one><input name=email></form><form id=two><input name=email></form>"

      assert {:error,
              %Failure{
                kind: :multiple_matches,
                request: %{ancestor_selector: "form", descendant: "input[name='email']"},
                candidates: [_, _]
              }} =
               Query.find_ancestor(html, "form", "input[name='email']")
    end

    test "retains potential ancestors when descendant is absent" do
      html = "<form id=super></form><input id=greeting>"
      assert {:error, %Failure{kind: :not_found, candidates: candidates}} = Query.find_ancestor(html, "form", "#greeting")
      assert {"form", [{"id", "super"}], []} = Html.element(candidates)
    end

    test "reports missing ancestor selector" do
      assert {:error, %Failure{kind: :not_found, candidates: [], request: %{ancestor_selector: "form"}}} =
               Query.find_ancestor("<input id=greeting>", "form", "#greeting")
    end

    test "finds ancestor with descendant text" do
      html = "<form id=super><button>Save</button></form><form id=other><button>Reset</button></form>"
      assert {:ok, element} = Query.find_ancestor(html, "form", {"button", "Save"})
      assert {"form", [{"id", "super"}], _} = Html.element(element)
    end

    test "accepts descendant selector and text map" do
      assert {:ok, _} =
               Query.find_ancestor("<form><button>Save</button></form>", "form", %{selector: "button", text: "Save"})
    end

    test "reports multiple ancestors matching descendant text" do
      html = "<form id=one><button>Save</button></form><form id=two><button>Save</button></form>"

      assert {:error, %Failure{kind: :multiple_matches, candidates: [_, _], request: %{descendant: {"button", "Save"}}}} =
               Query.find_ancestor(html, "form", {"button", "Save"})
    end

    test "retains ancestors that do not contain text descendant" do
      assert {:error, %Failure{kind: :not_found, candidates: candidates}} =
               Query.find_ancestor("<form></form><button>Save</button>", "form", {"button", "Save"})

      assert {"form", _, []} = Html.element(candidates)
    end

    test "has_ancestor is true for selector" do
      assert Query.has_ancestor?("<form><input id=greeting></form>", "form", "#greeting")
    end

    test "has_ancestor is false for selector" do
      refute Query.has_ancestor?("<form></form><input id=greeting>", "form", "#greeting")
    end

    test "has_ancestor supports descendant text" do
      html = "<form><button>Save</button></form><form><button>Reset</button></form>"
      assert Query.has_ancestor?(html, "form", {"button", "Save"})
      refute Query.has_ancestor?(html, "form", {"button", "Delete"})
    end
  end
end
