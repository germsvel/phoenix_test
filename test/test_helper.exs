ExUnit.start()

{:ok, _} = Supervisor.start_link([{Phoenix.PubSub, name: PhoenixTest.PubSub}], strategy: :one_for_one)
{:ok, _} = PhoenixTest.Endpoint.start_link()

{:ok, _} = Application.ensure_all_started(:wallaby)
Application.put_env(:wallaby, :base_url, PhoenixTest.Endpoint.url())
