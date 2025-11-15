ExUnit.start()

:butterbee.init()
{:ok, _} = Supervisor.start_link([{Phoenix.PubSub, name: PhoenixTest.PubSub}], strategy: :one_for_one)
{:ok, _} = PhoenixTest.WebApp.Endpoint.start_link()

Application.put_env(:phoenix_test, :base_url, PhoenixTest.WebApp.Endpoint.url())
# {:ok, _} = Application.ensure_all_started(:credo)
