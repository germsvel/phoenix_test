defmodule PhoenixTest.WebApp.LayoutView do
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: PhoenixTest.WebApp.Endpoint,
    router: PhoenixTest.WebApp.Router,
    statics: ~w(assets fonts images favicon.ico robots.txt)

  def render("root.html", assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en" class="[scrollbar-gutter:stable]">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={Phoenix.Controller.get_csrf_token()} />
        <.live_title>{assigns[:page_title] || "PhoenixTest is the best!"}</.live_title>
        <link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />
        <script>
          console.log("Hey, I'm some JavaScript!")
        </script>
        <script defer phx-track-static type="text/javascript" src={~p"/assets/app.js"}>
        </script>
      </head>
      <body class="bg-white antialiased">
        {@inner_content}
      </body>
    </html>
    """
  end

  def render("app.html", assigns) do
    ~H"""
    <main class="px-4 py-20 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-2xl">
        <div id="flash-group">
          <.flash kind={:info} title="Success!" flash={@flash} />
          <.flash kind={:error} title="Error!" flash={@flash} />
        </div>
        {@inner_content}
      </div>
    </main>
    """
  end

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      role="alert"
      class={[
        "fixed top-2 right-2 mr-2 w-80 sm:w-96 z-50 rounded-lg p-3 ring-1",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900",
        @kind == :error && "bg-rose-50 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
      ]}
    >
      <p class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        {@title}
      </p>
      <p class="mt-2 text-sm leading-5">{msg}</p>
    </div>
    """
  end
end
