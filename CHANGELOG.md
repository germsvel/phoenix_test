Changelog
=========

Noteworthy changes are included here. For a full version of changes, see git
history.

To see dates a version was published, see the [hex package
page](https://hex.pm/packages/phoenix_test)

# 0.2.0

## Breaking changes

- Update our static implementation to raise when we find many elements. That
  brings it in line with how our LiveView implementation works. See commit
  [daa4dca](https://github.com/germsvel/phoenix_test/commit/daa4dca)

## Improved

- Improves error messages in assertions. See commit
  [c995fc1](https://github.com/germsvel/phoenix_test/commit/c995fc1)

# 0.1.1

## Added

- Adds `click_link/3` and `click_button/3` which allow for specifying a CSS
  selector. See commit [c7401b6](https://github.com/germsvel/phoenix_test/commit/c7401b6).

# 0.1.0

- Initial version of the library.
