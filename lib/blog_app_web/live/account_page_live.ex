defmodule BlogAppWeb.AccountPageLive do
  use BlogAppWeb, :live_view

  alias BlogApp.Accounts
  alias BlogApp.Articles

  def render(assigns) do
    ~H"""
      <div>
        <div><%= @account.name %></div>
        <div><%= @account.email %></div>
        <div><%= @account.introduction %></div>
        <div>Articles count: <%= @articles_count %></div>
        <div :if={@account.id == @current_account_id}>
          <a href={~p"/accounts/settings"}>
            Edit profile
          </a>
        </div>
      </div>

      <div>
        <div>
          <a href={~p"/accounts/profile/#{@account.id}"}>Articles</a>
          <a
            href={~p"/accounts/profile/#{@account.id}/draft"}
            :if={@account.id == @current_account_id}
          >
            Draft
          </a>
          <a href={~p"/accounts/profile/#{@account.id}/liked"}>
            Liked
          </a>
        </div>
        <div>
          <%= if length(@articles) > 0 do %>
            <div :for={article <- @articles} class="mt-2">
              <a href={~p"/accounts/profile/#{article.account.id}"}>
                <%= article.account.name %>
              </a>
              <a href={~p"/articles/show/#{article.id}"} :if={@live_action in [:info, :liked]}>
                <div><%= article.submit_date %></div>
                <h2><%= article.title %></h2>
                <div>Liked: <%= Enum.count(article.likes) %></div>
              </a>
              <a href={~p"/articles/#{article.id}/edit"} :if={@live_action == :draft}>
                <div><%= article.title %></div>
                <div :if={article.body}> <%= String.slice(article.body, 0..30) %></div>
              </a>
            </div>
          <% else %>
            <div>
              <%=
                case @live_action do
                  :info -> "No articles"
                  :draft -> "No draft articles"
                  :liked -> "No liked articles"
                end
              %>
            </div>
          <% end %>
        </div>
      </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"account_id" => account_id}, _uri, socket) do
    socket =
      socket
      |> assign(:account, Accounts.get_account!(account_id))
      |> apply_action(socket.assigns.live_action)
    {:noreply, socket}
  end

  defp apply_action(socket, :info) do
    account = socket.assigns.account
    current_account = socket.assigns.current_account
    current_account_id = get_current_account_id(current_account)

    articles =
      Articles.list_articles_for_account(account.id, current_account_id)

    socket
    |> assign(:articles, articles)
    |> assign(:articles_count, Enum.count(articles))
    |> assign(:current_account_id, current_account_id)
    |> assign(:page_title, account.name)
  end

  defp apply_action(socket, :draft) do
    account = socket.assigns.account
    current_account = socket.assigns.current_account
    current_account_id = get_current_account_id(current_account)

    if account.id == current_account_id do
      articles_count =
        current_account_id
        |> Articles.list_articles_for_account(current_account_id)
        |> Enum.count()

      socket
      |> assign(:articles, Articles.list_draft_articles_for_account(current_account_id))
      |> assign(:articles_count, articles_count)
      |> assign(:current_account_id, current_account_id)
      |> assign(:page_title, account.name <> " - draft")

    else
      redirect(socket, to: ~p"/accounts/profile/#{account.id}")
    end
  end

  defp apply_action(socket, :liked) do
    account = socket.assigns.account
    current_account_id = get_current_account_id(socket.assigns.current_account)

    socket
    |> assign(:articles, Articles.list_liked_articles_for_account(account.id))
    |> assign_article_count(account.id, current_account_id)
    |> assign(:current_account_id, current_account_id)
    |> assign(:page_title, account.name <> " - liked")
  end

  defp assign_article_count(socket, account_id, current_account_id) do
    articles_count =
      account_id
      |> Articles.list_articles_for_account(current_account_id)
      |> Enum.count()

    assign(socket, :articles_count, articles_count)
  end

  defp get_current_account_id(current_account) do
    Map.get(current_account || %{}, :id)
  end
end
