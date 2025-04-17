defmodule PhoenixTest.WebApp.MailingList do
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

defmodule PhoenixTest.WebApp.OrdinalInputsLive do
  @moduledoc false
  use Phoenix.LiveView
  use Phoenix.Component

  import PhoenixTest.WebApp.Components

  alias PhoenixTest.WebApp.MailingList

  def mount(_params, _session, socket) do
    changeset = MailingList.changeset(%MailingList{}, %{})

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
    <.form for={@form} phx-change="validate" phx-submit="submit">
      <.input field={@form[:title]} label="Title" />
      <.inputs_for :let={ef} field={@form[:emails]}>
        <input type="hidden" name="mailing_list[emails_sort][]" value={ef.index} />
        <.input label="Email" type="text" field={ef[:email]} placeholder="email" />
        <a class="underline" phx-click="remove-email" phx-value-index={ef.index}>
          Remove
        </a>
      </.inputs_for>

      <input type="hidden" name="mailing_list[emails_drop][]" />

      <button phx-click="add-email">Add Email</button>
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

  def handle_event("validate", %{"mailing_list" => params}, socket) do
    changeset = MailingList.changeset(%MailingList{}, params)
    {:noreply, assign(socket, changeset: changeset, form: to_form(changeset))}
  end

  def handle_event("add-email", _params, socket) do
    changeset = socket.assigns.changeset

    new_emails =
      Ecto.Changeset.get_field(changeset, :emails) ++ [%MailingList.Email{}]

    updated_changeset =
      MailingList.changeset(%{changeset.data | emails: new_emails}, %{})

    {:noreply, assign(socket, changeset: updated_changeset, form: to_form(updated_changeset))}
  end

  def handle_event("remove-email", %{"index" => index}, socket) do
    index = String.to_integer(index)
    current_emails = Ecto.Changeset.get_field(socket.assigns.changeset, :emails)

    new_emails = List.delete_at(current_emails, index)

    updated_changeset =
      MailingList.changeset(%{socket.assigns.changeset.data | emails: new_emails}, %{})

    {:noreply, assign(socket, changeset: updated_changeset, form: to_form(updated_changeset))}
  end

  def handle_event("submit", %{"mailing_list" => params}, socket) do
    changeset = MailingList.changeset(%MailingList{}, params)

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
