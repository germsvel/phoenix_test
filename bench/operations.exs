ExUnit.start()

defmodule PhoenixTest.OperationsBenchmark do
  @moduledoc """
  Benchmarks public PhoenixTest operations against the bundled example app.
  Sessions are prepared outside timed Benchee calls. Both visit variants use
  the same bounded timing loop in the ExUnit process: LiveViewTest cannot
  mount a LiveView from Benchee's worker process.
  """
  use ExUnit.Case, async: false

  setup_all do
    # All requests are dispatched in-process. Avoid opening the endpoint's
    # HTTP listener so unrelated socket traffic cannot skew measurements.
    endpoint = PhoenixTest.WebApp.Endpoint
    config = Application.fetch_env!(:phoenix_test, endpoint)
    Application.put_env(:phoenix_test, endpoint, Keyword.put(config, :server, false))

    {:ok, _} = Supervisor.start_link([{Phoenix.PubSub, name: PhoenixTest.PubSub}], strategy: :one_for_one)
    {:ok, _} = endpoint.start_link()
    :ok
  end

  test "static page operations" do
    conn = Phoenix.ConnTest.build_conn()
    session = PhoenixTest.visit(conn, "/page/index")
    filled = PhoenixTest.fill_in(session, "Email", with: "aragorn@example.com")

    Benchee.run(
      %{
        "static assert_has" => fn -> PhoenixTest.assert_has(session, "#title") end,
        "static click_link" => fn -> PhoenixTest.click_link(session, "Page 2") end,
        "static fill_in" => fn -> PhoenixTest.fill_in(session, "Email", with: "aragorn@example.com") end,
        "static select" => fn -> PhoenixTest.select(session, "Race", option: "Elf") end,
        "static check" => fn -> PhoenixTest.check(session, "Admin") end,
        "static choose" => fn -> PhoenixTest.choose(session, "Email Choice") end,
        "static click_button (submit)" => fn -> PhoenixTest.click_button(filled, "Save Email") end,
        "static submit" => fn -> PhoenixTest.submit(filled) end
      },
      warmup: 1,
      time: 2
    )
  end

  test "visit on static pages and LiveViews (same process and timer)" do
    # Benchee runs scenarios in workers; LiveViewTest requires the ExUnit
    # process. Alternate the order so neither variant always runs first.
    # Bound the samples since mounts stay alive until ExUnit cleans up.
    static = fn -> PhoenixTest.visit(Phoenix.ConnTest.build_conn(), "/page/index") end
    live = fn -> PhoenixTest.visit(Phoenix.ConnTest.build_conn(), "/live/index") end

    for _ <- 1..10 do
      static.()
      live.()
    end

    samples =
      for index <- 1..50 do
        if rem(index, 2) == 0 do
          {timed(static), timed(live)}
        else
          {live_us, static_us} = {timed(live), timed(static)}
          {static_us, live_us}
        end
      end

    {static_times, live_times} = Enum.unzip(samples)
    IO.puts("Visit baseline (10 warmups + 50 samples per variant, ExUnit process):")
    report_visit("static", static_times)
    report_visit("LiveView", live_times)
  end

  defp timed(fun) do
    {microseconds, _session} = :timer.tc(fun)
    microseconds
  end

  defp report_visit(name, times) do
    sorted = Enum.sort(times)

    IO.puts("  #{name}: median #{Enum.at(sorted, 25)} μs, mean #{Float.round(Enum.sum(sorted) / 50, 1)} μs")
  end

  test "LiveView operations" do
    conn = Phoenix.ConnTest.build_conn()
    session = PhoenixTest.visit(conn, "/live/index")
    check_session = PhoenixTest.visit(Phoenix.ConnTest.build_conn(), "/live/index")
    choose_session = PhoenixTest.visit(Phoenix.ConnTest.build_conn(), "/live/index")
    select_session = PhoenixTest.visit(Phoenix.ConnTest.build_conn(), "/live/index")
    no_change_select = PhoenixTest.visit(Phoenix.ConnTest.build_conn(), "/live/index")
    no_change_check = PhoenixTest.visit(Phoenix.ConnTest.build_conn(), "/live/index")
    patch_session = PhoenixTest.visit(Phoenix.ConnTest.build_conn(), "/live/index")
    click_session = PhoenixTest.visit(Phoenix.ConnTest.build_conn(), "/live/index")
    submit_session = PhoenixTest.visit(Phoenix.ConnTest.build_conn(), "/live/index")
    button_session = PhoenixTest.visit(Phoenix.ConnTest.build_conn(), "/live/index")
    filled = PhoenixTest.fill_in(submit_session, "User Name", with: "Aragorn")
    button_filled = PhoenixTest.fill_in(button_session, "User Name", with: "Aragorn")

    Benchee.run(
      %{
        "live assert_has" => fn -> PhoenixTest.assert_has(session, "#title") end,
        "live click_link (patch)" => fn -> PhoenixTest.click_link(patch_session, "Patch link") end,
        "live click_button (event)" => fn -> PhoenixTest.click_button(click_session, "Change h3") end,
        "live click_button (submit)" => fn -> PhoenixTest.click_button(button_filled, "Save Nested Form") end,
        "live submit" => fn -> PhoenixTest.submit(filled) end,
        "live fill_in (no change event)" => fn ->
          PhoenixTest.within(session, "#no-phx-change-form", fn s ->
            PhoenixTest.fill_in(s, "Name", with: "Aragorn")
          end)
        end,
        "live select" => fn -> PhoenixTest.select(select_session, "Race", option: "Elf") end,
        "live select (no change event)" => fn ->
          PhoenixTest.select(no_change_select, "User Admin", option: "True")
        end,
        "live check" => fn -> PhoenixTest.check(check_session, "Admin") end,
        "live check (no change event)" => fn -> PhoenixTest.check(no_change_check, "Payer") end,
        "live choose" => fn -> PhoenixTest.choose(choose_session, "Email Choice") end
      },
      warmup: 1,
      time: 2
    )
  end
end
