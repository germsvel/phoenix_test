{:ok, _} = Supervisor.start_link([{Phoenix.PubSub, name: PhoenixTest.PubSub}], strategy: :one_for_one)
{:ok, _} = PhoenixTest.WebApp.Endpoint.start_link()

session_setup_fn = fn input ->
  session = PhoenixTest.visit(Phoenix.ConnTest.build_conn(), "/page/index")
  {input, session}
end

Benchee.run(%{
  "PhoenixTest.assert_has/2" => {
    fn {_input, session} ->
      PhoenixTest.assert_has(session, "[data-role='title']")
    end,
    before_scenario: session_setup_fn
  },
  "PhoenixTest.assert_has/3, tag selector" => {
    fn {_input, session} ->
      PhoenixTest.assert_has(session, "li", text: "Aragorn")
    end,
    before_scenario: session_setup_fn
  },
  "PhoenixTest.assert_has/3, id+tag selector" => {
    fn {_input, session} ->
      PhoenixTest.assert_has(session, "#multiple-items li", text: "Aragorn")
    end,
    before_scenario: session_setup_fn
  }
})
