ExUnit.start()

{:ok, _} = PhoenixTest.Endpoint.start_link()

{:ok, _} = Application.ensure_all_started(:wallaby)
Application.put_env(:wallaby, :base_url, PhoenixTest.Endpoint.url())
