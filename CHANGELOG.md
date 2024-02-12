Changelog
=========

Noteworthy changes are included here. For a full version of changes, see git
history.

To see dates a version was published, see the [hex package
page](https://hex.pm/packages/phoenix_test)

## 0.2.4

### Added

- Handle form redirects from static pages. Commit
  [4c39920](https://github.com/germsvel/phoenix_test/commit/4c39920)
- Handle regular form submission from LiveView pages. Commit
  [fe755de](https://github.com/germsvel/phoenix_test/commit/fe755de)

### Fixes

- Use Html.raw/1 for more errors to handle nested buttons.
  [82e7415](https://github.com/germsvel/phoenix_test/commit/82e7415)

## 0.2.3

### Added

- Handle form redirects (to Live and static pages) from Live pages. Commit
  [531e5e9](https://github.com/germsvel/phoenix_test/commit/531e5e9)
- Expand documentation on nested forms. Commit
  [6809389](https://github.com/germsvel/phoenix_test/commit/6809389)

### Fixes

- Allow multiple matching elements in `assert_has`. Commit
  [ac0e167](https://github.com/germsvel/phoenix_test/commit/ac0e167)

## 0.2.2

### Added

- Raise `AssertionError` instead of `RuntimeError` in assertions for more
  consistent ExUnit error messages. Commit
  [117bc59](https://github.com/germsvel/phoenix_test/commit/117bc59)
- Update `fill_form` to handle that aren't direct children of the `form`
  element. Commit
  [46d6229](https://github.com/germsvel/phoenix_test/commit/46d6229)

## 0.2.1

### Added

- Improve printing of complex nested content in assertions. Commit
  [7151834](https://github.com/germsvel/phoenix_test/commit/7151834)
- Better error messages in forms when multiple submit buttons/inputs are found.
  Commit [82492c6](https://github.com/germsvel/phoenix_test/commit/82492c6)

### Fixes

- Allow using `refute_has` in pipes in the same way `assert_has` already works.
  Commit [0484979](https://github.com/germsvel/phoenix_test/commit/0484979)

## 0.2.0

### Breaking changes

- Update our static implementation to raise when we find many elements. That
  brings it in line with how our LiveView implementation works. Commit
  [daa4dca](https://github.com/germsvel/phoenix_test/commit/daa4dca)

### Improved

- Improves error messages in assertions. Commit [c995fc1](https://github.com/germsvel/phoenix_test/commit/c995fc1)

## 0.1.1

### Added

- Adds `click_link/3` and `click_button/3` which allow for specifying a CSS
  selector. Commit [c7401b6](https://github.com/germsvel/phoenix_test/commit/c7401b6).

## 0.1.0

- Initial version of the library.
