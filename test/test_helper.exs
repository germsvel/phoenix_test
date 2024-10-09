ExUnit.start()

{:ok, _} = Supervisor.start_link([{Phoenix.PubSub, name: PhoenixTest.PubSub}], strategy: :one_for_one)
{:ok, _} = PhoenixTest.Endpoint.start_link()

Application.put_env(:phoenix_test, :base_url, PhoenixTest.Endpoint.url())
