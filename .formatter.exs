# Used by "mix format"
[
  import_deps: [:phoenix],
  plugins: [Phoenix.LiveView.HTMLFormatter, Styler],
  inputs: ["{mix,.formatter}.exs", "*.{heex,ex,exs}", "{config,lib,test}/**/*.{heex,ex,exs}"]
]
