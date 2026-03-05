defmodule PhoenixTest.WebApp.DynamicInputsAddRemoveLive do
  @moduledoc false
  use Phoenix.LiveView
  use Phoenix.Component

  # Based on the LiveView docs example:
  # https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#inputs_for/1-dynamically-adding-and-removing-inputs
  import PhoenixTest.WebApp.Components

  alias __MODULE__.MailingList
  alias Phoenix.LiveView.JS

  defmodule MailingList do
    @moduledoc false
    use Ecto.Schema

    import Ecto.Changeset

    embedded_schema do
      field(:title, :string)

      embeds_many :emails, Email, on_replace: :delete do
        field(:email, :string)
        field(:name, :string)
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

    defp email_changeset(email, attrs) do
      cast(email, attrs, [:email, :name])
    end
  end

  def mount(_params, _session, socket) do
    changeset = MailingList.changeset(%MailingList{emails: [%MailingList.Email{}]}, %{})
    {:ok, socket |> assign_form(changeset) |> assign(submitted: false, emails: [])}
  end

  def render(assigns) do
    ~H"""
    <.form for={@form} phx-change="validate" phx-submit="submit">
      <.input field={@form[:title]} label="Title" />

      <.inputs_for :let={ef} field={@form[:emails]}>
        <input type="hidden" name="mailing_list[emails_sort][]" value={ef.index} />
        <.input label="Email" type="text" field={ef[:email]} />
        <.input label="Name" type="text" field={ef[:name]} />
        <button
          type="button"
          name="mailing_list[emails_drop][]"
          value={ef.index}
          phx-click={JS.dispatch("change")}
        >
          delete <span class="sr-only">{ef.index}</span>
        </button>
      </.inputs_for>

      <input type="hidden" name="mailing_list[emails_drop][]" />

      <button
        type="button"
        name="mailing_list[emails_sort][]"
        value="new"
        phx-click={JS.dispatch("change")}
      >
        add more
      </button>

      <button type="submit">Submit</button>
    </.form>

    <div :if={@submitted}>
      <h3>Submitted Values:</h3>
      <div>Title: {@form.params["title"]}</div>
      <%= for email <- @emails do %>
        <div data-role="email">{email}</div>
      <% end %>
    </div>
    """
  end

  def handle_event("validate", %{"mailing_list" => params}, socket) do
    changeset = MailingList.changeset(%MailingList{}, params)
    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("submit", %{"mailing_list" => params}, socket) do
    changeset = MailingList.changeset(%MailingList{}, params)

    emails =
      changeset
      |> Ecto.Changeset.get_field(:emails)
      |> Enum.map(& &1.email)
      |> Enum.reject(&is_nil/1)

    {:noreply, socket |> assign_form(changeset) |> assign(submitted: true, emails: emails)}
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset, as: :mailing_list))
  end
end
