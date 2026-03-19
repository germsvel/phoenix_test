defmodule PhoenixTest.HtmlTest do
  use ExUnit.Case, async: true

  alias PhoenixTest.Html

  describe "element_text" do
    test "extracts text from parsed html, removing extra tags & whitespace" do
      html = """
      <label>
        hello
        <br />
        <em>world!</em>
      </label>
      """

      result =
        html
        |> Html.parse_fragment()
        |> Html.element_text()

      assert result == "hello world!"
    end

    test "extracts the text from the top level element along with nested text" do
      html = """
      <div>
        hello
        <a href="/">elixir</a>
        <span>and</span>
        <small>phoenix</small>
        </br>
        <em>
          test
          world!
        </em>
      </div>
      """

      result =
        html
        |> Html.parse_fragment()
        |> Html.element_text()

      assert result == "hello elixir and phoenix test world!"
    end

    test "extracts text but excludes select elements and their options" do
      html = """
      <div>
        <p>Choose an option:</p>
        <select>
          <option value="1">First option</option>
          <option value="2">Second option</option>
        </select>
        <p>More text here</p>
      </div>
      """

      result =
        html
        |> Html.parse_fragment()
        |> Html.element_text()

      assert result == "Choose an option: More text here"
    end

    test "extracts text from label but excludes textarea value" do
      html = """
      <label for="wrapped-notes">
        Wrapped notes

        <textarea name="wrapped-notes" rows="5" cols="33">
          Prefilled wrapped notes
        </textarea>
      </label>
      """

      result =
        html
        |> Html.parse_fragment()
        |> Html.element_text()

      assert result == "Wrapped notes"
    end

    test "includes textarea text if it's the top-level element" do
      html = """
      <textarea name="wrapped-notes" rows="5" cols="33">
        Prefilled notes
      </textarea>
      """

      result =
        html
        |> Html.parse_fragment()
        |> Html.element_text()

      assert result == "Prefilled notes"
    end

    test "includes alt text from images" do
      html = """
      <a href="/profile">
        <img src="avatar.jpg" alt="User avatar" />
        John Doe
      </a>
      """

      result =
        html
        |> Html.parse_fragment()
        |> Html.element_text()

      assert result =~ "User avatar"
      assert result =~ "John Doe"
    end

    test "ignores images with empty alt attributes" do
      html = """
      <a href="/">
        <img src="logo.png" alt="" />
        Home
      </a>
      """

      result =
        html
        |> Html.parse_fragment()
        |> Html.element_text()

      assert result == "Home"
    end

    test "ignores images without alt attribute" do
      html = """
      <a href="/">
        <img src="logo.png" />
        Home
      </a>
      """

      result =
        html
        |> Html.parse_fragment()
        |> Html.element_text()

      assert result == "Home"
    end

    test "includes multiple alt texts from multiple images" do
      html = """
      <div>
        <img src="icon1.png" alt="First icon" />
        Some text
        <img src="icon2.png" alt="Second icon" />
      </div>
      """

      result =
        html
        |> Html.parse_fragment()
        |> Html.element_text()

      assert result =~ "First icon"
      assert result =~ "Some text"
      assert result =~ "Second icon"
    end

    test "uses aria-label when present on supported elements" do
      html = """
      <button aria-label="Close dialog">×</button>
      """

      result =
        html
        |> Html.parse_fragment()
        |> Html.element_text()

      assert result == "Close dialog"
    end

    test "aria-label replaces element content on supported elements" do
      html = """
      <button aria-label="Close">×</button>
      """

      result =
        html
        |> Html.parse_fragment()
        |> Html.element_text()

      assert result == "Close"
      refute result =~ "×"
    end

    test "includes aria-label if elements are nested" do
      html = """
      <div>
        <button aria-label="Yes">✅</button>
        Some text
        <button aria-label="No">❌</button>
      </div>
      """

      result =
        html
        |> Html.parse_fragment()
        |> Html.element_text()

      assert result =~ "Yes"
      assert result =~ "Some text"
      assert result =~ "No"
    end

    test "ignores empty aria-label" do
      html = """
      <button aria-label="">Click me</button>
      """

      result =
        html
        |> Html.parse_fragment()
        |> Html.element_text()

      assert result == "Click me"
    end

    test "falls back to content when aria-label is only whitespace" do
      html = """
      <button aria-label="  ">Click me</button>
      """

      result =
        html
        |> Html.parse_fragment()
        |> Html.element_text()

      assert result == "Click me"
    end

    test "aria-label works on links" do
      html = """
      <a href="/settings" aria-label="Account settings">⚙️</a>
      """

      result =
        html
        |> Html.parse_fragment()
        |> Html.element_text()

      assert result == "Account settings"
      refute result =~ "⚙️"
    end

    test "ignores aria-label on paragraph elements (not supported)" do
      html = """
      <p aria-label="This should be ignored">Visible text</p>
      """

      result =
        html
        |> Html.parse_fragment()
        |> Html.element_text()

      assert result == "Visible text"
      refute result =~ "This should be ignored"
    end

    test "ignores aria-label on strong elements (not supported)" do
      html = """
      <strong aria-label="Not used">Bold text</strong>
      """

      result =
        html
        |> Html.parse_fragment()
        |> Html.element_text()

      assert result == "Bold text"
      refute result =~ "Not used"
    end

    test "ignores aria-label on em elements (not supported)" do
      html = """
      <em aria-label="Not used">Emphasized text</em>
      """

      result =
        html
        |> Html.parse_fragment()
        |> Html.element_text()

      assert result == "Emphasized text"
      refute result =~ "Not used"
    end

    test "aria-label works on divs (supported as generic container)" do
      html = """
      <div aria-label="Custom widget">Content</div>
      """

      result =
        html
        |> Html.parse_fragment()
        |> Html.element_text()

      assert result == "Custom widget"
      refute result =~ "Content"
    end

    test "extracts alt attribute from input type=image elements" do
      html = """
      <input type="image" src="/submit.png" alt="Submit form" />
      """

      result =
        html
        |> Html.parse_fragment()
        |> Html.element_text()

      assert result == "Submit form"
    end

    test "ignores empty alt on input type=image elements" do
      html = """
      <input type="image" src="/submit.png" alt="" />
      """

      result =
        html
        |> Html.parse_fragment()
        |> Html.element_text()

      assert result == ""
    end

    test "extracts alt from img in link (as rendered by LiveView)" do
      # This simulates how LiveView renders the HTML
      html = """
      <a href="/live/page_2" data-phx-link="redirect" data-phx-link-state="push"><img src="/images/profile.png" alt="View profile"/> User Profile
      </a>
      """

      result =
        html
        |> Html.parse_fragment()
        |> Html.element_text()

      assert result =~ "View profile"
      assert result =~ "User Profile"
    end
  end
end
