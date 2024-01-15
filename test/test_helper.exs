ExUnit.start()

Application.put_env(:phoenix_test, PhoenixTest.Endpoint, [])
{:ok, _} = PhoenixTest.Endpoint.start_link()
