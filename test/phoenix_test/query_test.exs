defmodule PhoenixTest.QueryTest do
  use ExUnit.Case, async: true

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
end
