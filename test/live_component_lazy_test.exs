defmodule LiveComponentLazyTest do
  use ExUnit.Case
  use Phoenix.ConnTest
  import ComponentTestHelper
  import Phoenix.LiveViewTest

  @endpoint Endpoint

  setup_all do
    Endpoint.start_link()
    :ok
  end

  defmodule Column do
    use Surface.Component

    alias Surface.BaseComponent.LazyContent

    property title, :string, required: true
    property item, :any, lazy: true, required: true

    def render(assigns) do
      [%LazyContent{func: func}] = non_empty_children(assigns.content)
      {:data, Map.put(assigns, :func, func)}
    end
  end

  defmodule Grid do
    use Surface.LiveComponent

    property items, :list, required: true

    def render(assigns) do
      cols = children_by_type(assigns.content, Column)

      ~H"""
      <table>
        <th>
          <%= for col <- cols do %>
            <td>
              {{ col.title }}
            </td>
          <% end %>
        </th>
        <%= for item <- @items do %>
          <tr>
            <%= for col <- cols do %>
              <td>
                {{ col.func.(item) }}
              </td>
            <% end %>
          </tr>
        <% end %>
      </table>
      """
    end
  end

  defmodule View do
    use Surface.LiveView

    def render(assigns) do
      items = [%{id: 1, name: "First"}, %{id: 2, name: "Second"}]
      ~H"""
      <Grid items={{ items }}>
        <Column item="item" title="ID">
          Id: {{ item.id }}
        </Column>
        <Column item="item" title="NAME">
          Name: {{ item.name }}
        </Column>
      </Grid>
      """
    end
  end

  test "render inner content" do
    {:ok, _view, html} = live_isolated(build_conn(), View)

    assert_html html =~ """
    <table>
      <th>
        <td>ID</td>
        <td>NAME</td>
      </th>
      <tr>
        <td>Id: 1</td>
        <td>Name: First</td>
      </tr>
      <tr>
        <td>Id: 2</td>
        <td>Name: Second</td>
      </tr>
    </table>
    """
  end
end
