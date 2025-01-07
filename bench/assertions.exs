import PhoenixTest

{:ok, _} = Supervisor.start_link([{Phoenix.PubSub, name: PhoenixTest.PubSub}], strategy: :one_for_one)
{:ok, _} = PhoenixTest.WebApp.Endpoint.start_link()

conn = Phoenix.ConnTest.build_conn()

Benchee.run(%{
  "assert_has/2" => fn ->
    conn
    |> visit("/page/index")
    |> assert_has("[data-role='title']")
  end
})
