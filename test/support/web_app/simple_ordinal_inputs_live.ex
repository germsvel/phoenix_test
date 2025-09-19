defmodule PhoenixTest.WebApp.SimpleMailingList do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  embedded_schema do
    field(:title, :string)

    embeds_many :emails, Email, on_replace: :delete do
      field(:email, :string)
    end
  end

  def changeset(list, attrs) do
    list
    |> cast(attrs, [:title])
    |> cast_embed(:emails,
      with: &email_changeset/2,
      sort_param: :emails_sort,
      drop_param: :emails_drop
    )
  end

  def email_changeset(email_notification, attrs) do
    cast(email_notification, attrs, [:email])
  end
end

defmodule PhoenixTest.WebApp.SimpleOrdinalInputsLive do
  @moduledoc false
  use Phoenix.LiveView
  use Phoenix.Component

  import PhoenixTest.WebApp.Components

  alias PhoenixTest.WebApp.SimpleMailingList

  def mount(_params, _session, socket) do
    email = %SimpleMailingList.Email{}
    changeset = SimpleMailingList.changeset(%SimpleMailingList{emails: [email]}, %{})

    {:ok,
     assign(socket,
       changeset: changeset,
       form: to_form(changeset),
       submitted: false,
       emails: []
     )}
  end

  def render(assigns) do
    ~H"""
    <.form for={@form} phx-submit="submit">
      <.input field={@form[:title]} label="Title" />
      <.inputs_for :let={ef} field={@form[:emails]}>
        <.input label="Email" type="text" field={ef[:email]} placeholder="email" />
      </.inputs_for>

      <button type="submit">Submit</button>
    </.form>

    <div>
      <%= if @submitted do %>
        <h3>Submitted Values:</h3>
        <div>Title: {@form.params["title"]}</div>
        <%= for email <- @emails do %>
          <div data-role="email">{email}</div>
        <% end %>
      <% end %>
    </div>
    """
  end

  def handle_event("submit", %{"simple_mailing_list" => params}, socket) do
    changeset = SimpleMailingList.changeset(%SimpleMailingList{}, params)

    emails =
      changeset
      |> Ecto.Changeset.get_field(:emails)
      |> Enum.map(fn email -> email.email end)
      |> Enum.reject(&is_nil/1)

    {:noreply,
     assign(socket,
       changeset: changeset,
       form: to_form(changeset),
       submitted: true,
       emails: emails
     )}
  end
end
