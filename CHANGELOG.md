Changelog
=========

Noteworthy changes are included here. For a full version of changes, see git
history.

To see dates a version was published, see the [hex package
page](https://hex.pm/packages/phoenix_test)

## 0.9.1

- fix: Go back to excluding fields in `element_text`. Remove HTML.text (#273) [bb3380f]

[bb3380f]: https://github.com/germsvel/phoenix_test/commit/bb3380f

## 0.9.0

### Added

- feat: Target nested LiveViews with `within/2` (#270) [dd34446]

### Improvements

- Scope selectors in `within/2` for non-form actions [729e3cb]

### Fixes

- fix: only filter by element text when finding labels [d19c6cf]

[729e3cb]: https://github.com/germsvel/phoenix_test/commit/729e3cb
[d19c6cf]: https://github.com/germsvel/phoenix_test/commit/d19c6cf
[dd34446]: https://github.com/germsvel/phoenix_test/commit/dd34446

## 0.8.3

### Fixes

- Fix double textarea fill-in bug (Improve `HTML.inner_text`. Rename `element_text`) [37bc521]
- Fix: button type="button" should not submit form (#263) [af62179]

[37bc521]: https://github.com/germsvel/phoenix_test/commit/37bc521
[af62179]: https://github.com/germsvel/phoenix_test/commit/af62179

## 0.8.2

### Fixes

- Fix: keep provided selector in `click_button/3` [97f664d]

[97f664d]: https://github.com/germsvel/phoenix_test/commit/97f664d

## 0.8.1

### Fixes

- Fix: allow multiple select and checkboxes [334af88]
- Fix: Consider nested text in labels [c73ab4a]

[334af88]: https://github.com/germsvel/phoenix_test/commit/334af88
[c73ab4a]: https://github.com/germsvel/phoenix_test/commit/c73ab4a

## 0.8.0

### Improvements

- Support LiveView 1.1 ([9ced344]), and replace Floki with LazyHTML ([c6c2483], [1c45a80])
  - Note: Drops LiveView 0.20 in deps [499c3aa]
  - Boolean attribute support [72e37fd]

- Add credo NoOpenBrowser check [b1add28]
- Support phx-value and JS command values with uncheck [63c0c2a]

### Fixes

- Preserve order of appearance for array inputs [5fd0f32]

[1c45a80]: https://github.com/germsvel/phoenix_test/commit/1c45a80
[b1add28]: https://github.com/germsvel/phoenix_test/commit/b1add28
[499c3aa]: https://github.com/germsvel/phoenix_test/commit/499c3aa
[32dd749]: https://github.com/germsvel/phoenix_test/commit/32dd749
[c6c2483]: https://github.com/germsvel/phoenix_test/commit/c6c2483
[b30665d]: https://github.com/germsvel/phoenix_test/commit/b30665d
[9ced344]: https://github.com/germsvel/phoenix_test/commit/9ced344
[72e37fd]: https://github.com/germsvel/phoenix_test/commit/72e37fd
[5fd0f32]: https://github.com/germsvel/phoenix_test/commit/5fd0f32
[63c0c2a]: https://github.com/germsvel/phoenix_test/commit/63c0c2a

## 0.7.1

### Improvements

- Updated deps versions (Phoenix 1.8 support) [03fb661]
- Use Floki 0.38 and fix deprecations [26575bc], [c479154]

### Fixes

- Fix phx-trigger-action handling for dynamically rendered forms [fe5e986]
- Fix: `assert_path` handles nested query params [6a56cf9]

[fe5e986]: https://github.com/germsvel/phoenix_test/commit/fe5e986
[03fb661]: https://github.com/germsvel/phoenix_test/commit/03fb661
[26575bc]: https://github.com/germsvel/phoenix_test/commit/26575bc
[c479154]: https://github.com/germsvel/phoenix_test/commit/c479154
[6a56cf9]: https://github.com/germsvel/phoenix_test/commit/6a56cf9


## 0.7.0

### Potentially breaking change

- If you test uploads. PhoenixTest will now automatically trigger `phx-change`
  on `upload`. If you were previously triggering `phx-change` after your
  `upload`, you might now get duplicate `phx-change` events. See PR [#162] or
  commit [8edd7b4] for more information.

### New

- Adds: asserting by value and label (#204). Commit [515242d]
- Adds asserting & refuting by `:value` (#199). Commit [6271e81]

### Improvements

- Allow `JS.patch` in `phx-click` bindings. Commit [6012517]
- Handles LiveView forms that remove elements (#202). Commit [6f610f2]
- Allow empty maps to be passed into `assert_path` as `query_params` (#196).
  Commit [04ca498]
- `assert_path` handles query params with [] (#195). Commit [ac52f8b]
- Include simple `phx-*` attributes in selectors (#193). Commit [a327ccf]

### Fixes

- Do not raise non-existent path if URL is external (#206). Commits [891733f]
- Pass the original filter text from `click_button/2` when calling
  `click_button/3` (#222). Commit [dc17378]
- Fix: Find select nested in label (#210). Commit [450ad7d]
- return empty value for button if name is present and no value is found (#220).
  Commit [45ee501]
- Use Jason instead of native JSON to support < 1.18. Commit [632a5c6]
- Fix: pass view to assert_redirect. Commit [2b73714]
- Fix: Handle prefilled values for type=email etc. Commit [ec4440d]
- Test all "simple-value" input defaults. Commit [45b62ca]
- Check local path's endpoint at runtime to fix warning. Commit [1dbf12e]

[#162]: https://github.com/germsvel/phoenix_test/pull/162
[dc17378]: https://github.com/germsvel/phoenix_test/commit/dc17378
[1dbf12e]: https://github.com/germsvel/phoenix_test/commit/1dbf12e
[f9d1bb9]: https://github.com/germsvel/phoenix_test/commit/f9d1bb9
[45ee501]: https://github.com/germsvel/phoenix_test/commit/45ee501
[450ad7d]: https://github.com/germsvel/phoenix_test/commit/450ad7d
[632a5c6]: https://github.com/germsvel/phoenix_test/commit/632a5c6
[6012517]: https://github.com/germsvel/phoenix_test/commit/6012517
[d99c572]: https://github.com/germsvel/phoenix_test/commit/d99c572
[7a9b97b]: https://github.com/germsvel/phoenix_test/commit/7a9b97b
[891733f]: https://github.com/germsvel/phoenix_test/commit/891733f
[b1400b3]: https://github.com/germsvel/phoenix_test/commit/b1400b3
[515242d]: https://github.com/germsvel/phoenix_test/commit/515242d
[8edd7b4]: https://github.com/germsvel/phoenix_test/commit/8edd7b4
[6f610f2]: https://github.com/germsvel/phoenix_test/commit/6f610f2
[2b73714]: https://github.com/germsvel/phoenix_test/commit/2b73714
[2f6f3f6]: https://github.com/germsvel/phoenix_test/commit/2f6f3f6
[6271e81]: https://github.com/germsvel/phoenix_test/commit/6271e81
[45b62ca]: https://github.com/germsvel/phoenix_test/commit/45b62ca
[ec4440d]: https://github.com/germsvel/phoenix_test/commit/ec4440d
[04ca498]: https://github.com/germsvel/phoenix_test/commit/04ca498
[ac52f8b]: https://github.com/germsvel/phoenix_test/commit/ac52f8b
[a327ccf]: https://github.com/germsvel/phoenix_test/commit/a327ccf

## 0.6.0

### Breaking changes & deprecations

- (potentially breaking) Raise error when visiting an defined route. Commit [668448a]
- Deprecate select with `:from` in favor of `:option` (#191). Commit [071c3f3]

For a more detailed explanation, see the [Upgrade
guides](https://hexdocs.pm/phoenix_test/upgrade_guides.html)

### Improvements

- Simplify timeout logic. Attempt faster checks. Commits [24b31e5], [a053b51],
[d17baef], [1819f52], [1182dba]

- Allow nesting of `within/3` (#189). Commit [94c716f]
- Allow calling `visit/2` sequentially. Commit [230c6a1]
- Include default email input fields in form data (#180). Commit [5e36c09]
- Add mix benchmark alias to run benchmarks. Commit [0642aeb]
- Support role="button" for `click_button/2`. Commit [1dec249]
- Document reason behind `fill_in` needing a label (#188). Commit [74732ab]
- Docs: Mention playwright driver (#179). Commit [7619257]

### Fixes

- Fix documentation typo on  docs. Commit [756cc4c]
- Throw nice error messages for `render_upload` errors (#177). Commit [a1cf133]

[071c3f3]: https://github.com/germsvel/phoenix_test/commit/071c3f3
[a053b51]: https://github.com/germsvel/phoenix_test/commit/a053b51
[d17baef]: https://github.com/germsvel/phoenix_test/commit/d17baef
[1dec249]: https://github.com/germsvel/phoenix_test/commit/1dec249
[a4fb70a]: https://github.com/germsvel/phoenix_test/commit/a4fb70a
[3c601c4]: https://github.com/germsvel/phoenix_test/commit/3c601c4
[ce95e76]: https://github.com/germsvel/phoenix_test/commit/ce95e76
[94c716f]: https://github.com/germsvel/phoenix_test/commit/94c716f
[230c6a1]: https://github.com/germsvel/phoenix_test/commit/230c6a1
[a1cf133]: https://github.com/germsvel/phoenix_test/commit/a1cf133
[5e36c09]: https://github.com/germsvel/phoenix_test/commit/5e36c09
[74732ab]: https://github.com/germsvel/phoenix_test/commit/74732ab
[1819f52]: https://github.com/germsvel/phoenix_test/commit/1819f52
[1182dba]: https://github.com/germsvel/phoenix_test/commit/1182dba
[24b31e5]: https://github.com/germsvel/phoenix_test/commit/24b31e5
[668448a]: https://github.com/germsvel/phoenix_test/commit/668448a
[7619257]: https://github.com/germsvel/phoenix_test/commit/7619257
[0642aeb]: https://github.com/germsvel/phoenix_test/commit/0642aeb
[756cc4c]: https://github.com/germsvel/phoenix_test/commit/756cc4c

## 0.5.2

### Improvements

- Allow wildcards in `assert_path` (#163). Commit [aec2a0d]
- Add assertion benchmarks (#165). Commit [549cd49]

- Improve `:timeout` implementation for assertion helpers.
  - Improve LiveViewWatcher child spec. Commits [a3efdce], [31a5b79], [5da3bc6]
  - Start LiveViewWatcher under the test supervisor. Commit [bbcaf35]
  - Allow watcher to watch multiple views. Commit [0202671]
  - Watch sequential LiveViews (via redirects) and async behavior. Commit
    [f07c187]

### Fixes

- Catch exits when checking async pids. Commit [7f34790]
- Use LiveView.Channel to fetch async pids. Commit [8721948]

[5da3bc6]: https://github.com/germsvel/phoenix_test/commit/5da3bc6
[e42543b]: https://github.com/germsvel/phoenix_test/commit/e42543b
[9eeecad]: https://github.com/germsvel/phoenix_test/commit/9eeecad
[549cd49]: https://github.com/germsvel/phoenix_test/commit/549cd49
[8984387]: https://github.com/germsvel/phoenix_test/commit/8984387
[c9f96c1]: https://github.com/germsvel/phoenix_test/commit/c9f96c1
[ba5d999]: https://github.com/germsvel/phoenix_test/commit/ba5d999
[8721948]: https://github.com/germsvel/phoenix_test/commit/8721948
[f07c187]: https://github.com/germsvel/phoenix_test/commit/f07c187
[0202671]: https://github.com/germsvel/phoenix_test/commit/0202671
[aec2a0d]: https://github.com/germsvel/phoenix_test/commit/aec2a0d
[7f34790]: https://github.com/germsvel/phoenix_test/commit/7f34790
[89f31ff]: https://github.com/germsvel/phoenix_test/commit/89f31ff
[a3efdce]: https://github.com/germsvel/phoenix_test/commit/a3efdce
[31a5b79]: https://github.com/germsvel/phoenix_test/commit/31a5b79
[bbcaf35]: https://github.com/germsvel/phoenix_test/commit/bbcaf35
[6abace0]: https://github.com/germsvel/phoenix_test/commit/6abace0
[3d78969]: https://github.com/germsvel/phoenix_test/commit/3d78969
[1d420e6]: https://github.com/germsvel/phoenix_test/commit/1d420e6

### Docs

- Tag assertion docs. Commit [9eeecad]
- Fix fill_in/4 doc example. Commit [c9f96c1]

## 0.5.1

### Fixes

- Fix race condition. Ping LiveView instead of using "buffer". Commit [3d78969]

[3d78969]: https://github.com/germsvel/phoenix_test/commit/3d78969

## 0.5.0

### Added

- Adds `assert_has/3` | `refute_has/3` `:timeout` option Commit [7cb6a41].
- Support phx-trigger-action. Commit [f46ebc1].

### Improvements

- Allow LiveView 1.0. Commit [6e121c8].
- Allow labels to have line breaks. Commit [5949951].
- Make all functions part of the `Driver` protocol to allow for external
  drivers. Commits [8c9e3be], [af5d011], [ef3fca0].
- Raise error if implicit + explicit label found. Commit [9502fc7].

### Fixes

- Keep flash across Live -> Static redirects. Commit [ca7edf5].
- Make sure live redirect copy headers. Commit [ce490d3].
- Don't fail form when present disabled select. Commit [14b7bf0].
- Update current path on static submit. Commit [46d30bb].

[7cb6a41]: https://github.com/germsvel/phoenix_test/commit/7cb6a41
[9775097]: https://github.com/germsvel/phoenix_test/commit/9775097
[bfd1291]: https://github.com/germsvel/phoenix_test/commit/bfd1291
[5cc4ea3]: https://github.com/germsvel/phoenix_test/commit/5cc4ea3
[ca7edf5]: https://github.com/germsvel/phoenix_test/commit/ca7edf5
[a2eaa24]: https://github.com/germsvel/phoenix_test/commit/a2eaa24
[0af3b14]: https://github.com/germsvel/phoenix_test/commit/0af3b14
[4000203]: https://github.com/germsvel/phoenix_test/commit/4000203
[a346d09]: https://github.com/germsvel/phoenix_test/commit/a346d09
[5949951]: https://github.com/germsvel/phoenix_test/commit/5949951
[3506f7b]: https://github.com/germsvel/phoenix_test/commit/3506f7b
[8c9e3be]: https://github.com/germsvel/phoenix_test/commit/8c9e3be
[af5d011]: https://github.com/germsvel/phoenix_test/commit/af5d011
[ef3fca0]: https://github.com/germsvel/phoenix_test/commit/ef3fca0
[457144a]: https://github.com/germsvel/phoenix_test/commit/457144a
[14b7bf0]: https://github.com/germsvel/phoenix_test/commit/14b7bf0
[ce490d3]: https://github.com/germsvel/phoenix_test/commit/ce490d3
[ddacde8]: https://github.com/germsvel/phoenix_test/commit/ddacde8
[6e121c8]: https://github.com/germsvel/phoenix_test/commit/6e121c8
[9502fc7]: https://github.com/germsvel/phoenix_test/commit/9502fc7
[f46ebc1]: https://github.com/germsvel/phoenix_test/commit/f46ebc1
[46d30bb]: https://github.com/germsvel/phoenix_test/commit/46d30bb
[9eadbd9]: https://github.com/germsvel/phoenix_test/commit/9eadbd9
[6d6d40b]: https://github.com/germsvel/phoenix_test/commit/6d6d40b

## 0.4.2

### Fixes

- Fix: do not recycle fresh conn. Commit [24192e2]

[24192e2]: https://github.com/germsvel/phoenix_test/commit/24192e2

## 0.4.1

### Added

- Adds `select/4` `exact_option` option. Commit [f881da3]
- Copy headers across redirects . Commit [7ad8cb1]

### Fixes

- 🛠️  Fix active form vs form data loading . Commit [37302b9]
- Update `phx_click?` to check for valid JS commands. Commit [0d54b49]
- Deduplicate data passed to FormPayload (multi checkbox fix). Commit [e950ae4]

[0d54b49]: https://github.com/germsvel/phoenix_test/commit/0d54b49
[e950ae4]: https://github.com/germsvel/phoenix_test/commit/e950ae4
[7df460a]: https://github.com/germsvel/phoenix_test/commit/7df460a
[06e43e9]: https://github.com/germsvel/phoenix_test/commit/06e43e9
[ba34d9a]: https://github.com/germsvel/phoenix_test/commit/ba34d9a
[b37199d]: https://github.com/germsvel/phoenix_test/commit/b37199d
[3b175fb]: https://github.com/germsvel/phoenix_test/commit/3b175fb
[73f2b83]: https://github.com/germsvel/phoenix_test/commit/73f2b83
[37302b9]: https://github.com/germsvel/phoenix_test/commit/37302b9
[7ad8cb1]: https://github.com/germsvel/phoenix_test/commit/7ad8cb1
[5f106cd]: https://github.com/germsvel/phoenix_test/commit/5f106cd
[f881da3]: https://github.com/germsvel/phoenix_test/commit/f881da3
[5e05b4d]: https://github.com/germsvel/phoenix_test/commit/5e05b4d

## 0.4.0

### Breaking

- Select options were previously matched inexactly (as a substring match). That
  made it impossible to differentiate between two options where one was a subset
  of the other.

  For example, using `select(session, "Email", from: "Contact")` could not
  differentiate between the `Email` and `Email and SMS` options. Select options
  are now matched exactly. Commits [dc7ba01] and [e675561].

  This is a technically a bug fix, but it's also a potentially breaking change
  for existing tests that accidentally relied on that behavior. If you need
  inexact matches on options, please open an issue describing your use case.

[dc7ba01]: https://github.com/germsvel/phoenix_test/commit/dc7ba01
[e675561]: https://github.com/germsvel/phoenix_test/commit/e675561

### Added

- Adds `PhoenixTest.upload/3` to test file uploads. Commit [d717970]
- ✨ Form helpers now take `:exact` option. Commits [c4f9164] and [cb19f86]
- Form helpers now allow passing CSS selectors to target inputs. Commits
  [30b4eca], [12934b8], [bd595f8], [250e25e], [ef2999e]

[d717970]: https://github.com/germsvel/phoenix_test/commit/d717970
[c4f9164]: https://github.com/germsvel/phoenix_test/commit/c4f9164
[cb19f86]: https://github.com/germsvel/phoenix_test/commit/cb19f86
[30b4eca]: https://github.com/germsvel/phoenix_test/commit/30b4eca
[12934b8]: https://github.com/germsvel/phoenix_test/commit/12934b8
[bd595f8]: https://github.com/germsvel/phoenix_test/commit/bd595f8
[250e25e]: https://github.com/germsvel/phoenix_test/commit/250e25e
[ef2999e]: https://github.com/germsvel/phoenix_test/commit/ef2999e

### Improvements

- Raise nice error if field is missing `name` attribute. Commit [bb6950f]
- Docs: Add syntax highlighting for heex and html. Commit [e308f9f]

[bb6950f]: https://github.com/germsvel/phoenix_test/commit/bb6950f
[e308f9f]: https://github.com/germsvel/phoenix_test/commit/e308f9f

### Fixes

- Ignore `phx-*` attrs when inferring selector. Commit [b5d28c8]
- Don't error on default form input without name attribute. Commit [3bd6d7a]

[b5d28c8]: https://github.com/germsvel/phoenix_test/commit/b5d28c8
[3bd6d7a]: https://github.com/germsvel/phoenix_test/commit/3bd6d7a

## 0.3.2

### Added

- Check/uncheck works with phx-click outside forms. Commit [82fa973]
- Select works with phx-click outside forms. Commit [1493897]
- Radio buttons work with phx-click outside forms. Commit [8745ee1]

### Improvements

- Send `_target` event with phx-change events. Commit [ce093f1]
- Use `[id=<id>]` when querying by ID. Commits [5dd10f5] and [b79e8a3]
- Allow non-string data types as inputs to fields. Commit [5cc0936]
- Support default values on textareas. Commit [41c70e0]

### Fixes

- Fix `refute_has/2` to handle `:at` option without `text`. Commit [33a02bf]

[82fa973]: https://github.com/germsvel/phoenix_test/commit/82fa973
[1493897]: https://github.com/germsvel/phoenix_test/commit/1493897
[8745ee1]: https://github.com/germsvel/phoenix_test/commit/8745ee1
[ce093f1]: https://github.com/germsvel/phoenix_test/commit/ce093f1
[5dd10f5]: https://github.com/germsvel/phoenix_test/commit/5dd10f5
[b79e8a3]: https://github.com/germsvel/phoenix_test/commit/b79e8a3
[5cc0936]: https://github.com/germsvel/phoenix_test/commit/5cc0936
[41c70e0]: https://github.com/germsvel/phoenix_test/commit/41c70e0
[33a02bf]: https://github.com/germsvel/phoenix_test/commit/33a02bf

## 0.3.1

### Improvements

- Do not assume first option to be selected by default for multiple select. Commit [f146186]
- Handle multiple select in forms. Commit [6b6512d]
- Support pre-filled number inputs. Commit [81f03aa]

### Fixes

- Fix `open_browser/1` doc example. Commit [8f39959]
- Deep merge form data in nested/prefixed forms. Commit [34b73b0]
- Fix uncheck/2 in nested forms. Commit [e1a2408]
- Fix: Preserve '?' in checkbox name. Commit [2e032ef]
- Fix: Deep merge nested form button value (static). Commit [4303b4a]

[8f39959]: https://github.com/germsvel/phoenix_test/commit/8f39959
[34b73b0]: https://github.com/germsvel/phoenix_test/commit/34b73b0
[f146186]: https://github.com/germsvel/phoenix_test/commit/f146186
[81f03aa]: https://github.com/germsvel/phoenix_test/commit/81f03aa
[e1a2408]: https://github.com/germsvel/phoenix_test/commit/e1a2408
[2e032ef]: https://github.com/germsvel/phoenix_test/commit/2e032ef
[4303b4a]: https://github.com/germsvel/phoenix_test/commit/4303b4a
[6b6512d]: https://github.com/germsvel/phoenix_test/commit/6b6512d


## 0.3.0

### Added

- Adds `PhoenixTest.unwrap/2` as an escape hatch. Commit [87be9c5].

### Improvements

- We now handle redirects on `phx-change` events. Commit [cf1687c].
- Click button can submit forms when not nested in form. Commit [e173f5b].

### Fixes

- Fix `assert_path` live navigation with query params. Commit [6c58f27].

### Removed

- Removes deprecated `fill_form/3` and `submit_form/3`. Commit [fef7e82].
- Removes deprecated `assert_has`/`refute_has` with text as positional argument.
  Commit [82f4170].

[87be9c5]: https://github.com/germsvel/phoenix_test/commit/87be9c5
[cf1687c]: https://github.com/germsvel/phoenix_test/commit/cf1687c
[e173f5b]: https://github.com/germsvel/phoenix_test/commit/e173f5b
[6c58f27]: https://github.com/germsvel/phoenix_test/commit/6c58f27
[fef7e82]: https://github.com/germsvel/phoenix_test/commit/fef7e82
[82f4170]: https://github.com/germsvel/phoenix_test/commit/82f4170

## 0.2.13

### Deprecations

- Deprecates `fill_form/3` and `submit_form/3`. Commit [996458a]. See [upgrade
  guides] for more info.

[upgrade guides]: ./upgrade_guides.md#upgrading-to-0-2-13

### Additions

- Adds `fill_in/3` helper. Commit [6c7a1d2].
- Adds `select/3` helper. Commit [6efeadf].
- Adds `choose/2` helper. Commit [5f58604].
- Adds `within/3` helper. Commit [10b7269].
- Adds `submit/1` helper. Commit [fff82d1].
- Adds `check/2` and `uncheck/2` helpers. Commit [58110b4].

[996458a]: https://github.com/germsvel/phoenix_test/commit/996458a
[6c7a1d2]: https://github.com/germsvel/phoenix_test/commit/6c7a1d2
[6efeadf]: https://github.com/germsvel/phoenix_test/commit/6efeadf
[5f58604]: https://github.com/germsvel/phoenix_test/commit/5f58604
[10b7269]: https://github.com/germsvel/phoenix_test/commit/10b7269
[fff82d1]: https://github.com/germsvel/phoenix_test/commit/fff82d1
[58110b4]: https://github.com/germsvel/phoenix_test/commit/58110b4

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
