Changelog
=========

Noteworthy changes are included here. For a full version of changes, see git
history.

To see dates a version was published, see the [hex package
page](https://hex.pm/packages/phoenix_test)

## 0.2.12

### Fixes

- Fix checked checkbox being overridden by hidden input. Commit [a621f34]
- Handle multiple checkboxes inside a label. Commit [a8fc877]
- Fix `assert_path`/`refute_path` to handle live patching. Commit [48a29a3]
- Fix `assert_path`/`refute_path` to handle Live Navigation. Commit [842ab36]
- Fix `assert_has`/`refute_has` title matching exactly. Commit [7b2f243]
- Update `assert_has` examples in README to new API. Commit [cb7529b]

[a621f34]: https://github.com/germsvel/phoenix_test/commit/a621f34
[a8fc877]: https://github.com/germsvel/phoenix_test/commit/a8fc877
[48a29a3]: https://github.com/germsvel/phoenix_test/commit/48a29a3
[842ab36]: https://github.com/germsvel/phoenix_test/commit/842ab36
[7b2f243]: https://github.com/germsvel/phoenix_test/commit/7b2f243
[cb7529b]: https://github.com/germsvel/phoenix_test/commit/cb7529b

## 0.2.11

### Improvements

- Add `assert_path` and `refute_path` assertions helpers. Commit [f2ab02c]
- Include pre-selected text input values, selects, radio buttons, and checkboxes
  in form submissions. Commits [32a8da5], [d253eba], [ebba679]
- Include button's `name` and `value` if present. Commit [e54c64f]
- `click_button` submits form without having to `fill_form` before it does.
  Commit [8d16b7e]

### Fixes

- Follow multiple redirects in `Live.click_link`. Commit [28de102]

[f2ab02c]: https://github.com/germsvel/phoenix_test/commit/f2ab02c
[32a8da5]: https://github.com/germsvel/phoenix_test/commit/32a8da5
[d253eba]: https://github.com/germsvel/phoenix_test/commit/d253eba
[ebba679]: https://github.com/germsvel/phoenix_test/commit/ebba679
[e54c64f]: https://github.com/germsvel/phoenix_test/commit/e54c64f
[8d16b7e]: https://github.com/germsvel/phoenix_test/commit/8d16b7e
[28de102]: https://github.com/germsvel/phoenix_test/commit/28de102

## 0.2.10

### Improvements

- Add `count` option in assertions. Commit [16fd0a4]
- Add `exact` option in assertions. Commit [da772f1]
- Add `at` option in assertions. Commit [5da74ec]

### Deprecations

- Deprecate `assert_has/3` where `text` is the third argument (positional). Use
  `assert_has/3` with `text:` option instead. Commit [193c21a]

[16fd0a4]: https://github.com/germsvel/phoenix_test/commit/16fd0a4
[da772f1]: https://github.com/germsvel/phoenix_test/commit/da772f1
[5da74ec]: https://github.com/germsvel/phoenix_test/commit/5da74ec
[193c21a]: https://github.com/germsvel/phoenix_test/commit/193c21a

## 0.2.9

### Improvements

- Adds `assert_has/2` and `refute_has/2`. Commits [3756a47] and [9709b7a].
- Follows redirect on `visit/2`. Commit [b4f49be]

### Fixes

- Do not always assume `submit_button` after `fill_form` is for submitting the
  form. Commit [e193a07]

[3756a47]: https://github.com/germsvel/phoenix_test/commit/3756a47
[9709b7a]: https://github.com/germsvel/phoenix_test/commit/9709b7a
[b4f49be]: https://github.com/germsvel/phoenix_test/commit/b4f49be
[e193a07]: https://github.com/germsvel/phoenix_test/commit/e193a07

## 0.2.8

### Added

- Adds WSL2 for `open_browser/2`. Commit [b852014].
- Relax Elixir version requirement to 1.15. Commit [3cb9586]
- Support visiting non-200 pages in Static implementation. Commit [4964ab2].

[b852014]: https://github.com/germsvel/phoenix_test/commit/b852014
[3cb9586]: https://github.com/germsvel/phoenix_test/commit/3cb9586
[4964ab2]: https://github.com/germsvel/phoenix_test/commit/4964ab2

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
