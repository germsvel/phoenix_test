Changelog
=========

Noteworthy changes are included here. For a full version of changes, see git
history.

To see dates a version was published, see the [hex package
page](https://hex.pm/packages/phoenix_test)

## 0.2.7

### Fixes

- Fixes `open_browser/1` not existing. Commit [7407b19].

[7407b19]: https://github.com/germsvel/phoenix_test/commit/7407b19

## 0.2.6

### Added

- Adds `open_browser/1` function to both Live and Static implementations.
  Commit [b9d8347].
- Handle forms that use `data` attributes and `Phoenix.HTML.js` to submit forms.
  Commit [d699792].

### Fixes

- Correctly handles forms that PUT/DELETE (through hidden inputs). Commit
  [3efa4c0].

[b9d8347]: https://github.com/germsvel/phoenix_test/commit/b9d8347
[3efa4c0]: https://github.com/germsvel/phoenix_test/commit/3efa4c0
[d699792]: https://github.com/germsvel/phoenix_test/commit/d699792

## 0.2.5

### Added

- Introduce ability to assert and refute on page title. Commit [8552ec7].
- Handle regular form submission from LiveView pages when using `submit_form`.
  Commit [fc4d3ef].

### Fixes

- Improve Live validation of form fields to properly handle nested fields in
  forms. Commits [180dc0d] and [c275c0c].

[8552ec7]: https://github.com/germsvel/phoenix_test/commit/8552ec7
[fc4d3ef]: https://github.com/germsvel/phoenix_test/commit/fc4d3ef
[180dc0d]: https://github.com/germsvel/phoenix_test/commit/180dc0d
[c275c0c]: https://github.com/germsvel/phoenix_test/commit/c275c0c

## 0.2.4

### Added

- Handle form redirects from static pages. Commit
  [4c39920](https://github.com/germsvel/phoenix_test/commit/4c39920)
- Handle regular form submission from LiveView pages with `fill_form` +
  `click_button`. Commit [fe755de](https://github.com/germsvel/phoenix_test/commit/fe755de)

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
