ExUnit.start(exclude: [browser_verification: true])

{:ok, _} = PhoenixTest.Verification.Recorder.start_link([])
:ok = PhoenixTest.Verification.Telemetry.attach!()

{:ok, _} = Supervisor.start_link([{Phoenix.PubSub, name: PhoenixTest.PubSub}], strategy: :one_for_one)
{:ok, _} = PhoenixTest.WebApp.Endpoint.start_link()
{:ok, _} = PhoenixTest.AnotherWebApp.Endpoint.start_link()
{:ok, _} = Application.ensure_all_started(:credo)
