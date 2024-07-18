defmodule Doggo.Components do
  @moduledoc """
  This module defines macros that generate customized components.

  ## Usage

      defmodule MyAppWeb.CoreComponents do
        use Phoenix.Component
        import Doggo.Components

        accordion()
        action_bar()
        badge()
        cluster()
        tag()
        tree_item()
      end

  ## Common Options

  All component macros support the following options:

  - `name` - The name of the function of the generated component. Defaults to
    the macro name.
  - `base_class` - The base class used on the root element of the component. If
    not set, a default base class is used.
  - `modifiers` - A keyword list of modifier attributes. For each item, an
    attribute with the type `:string` is added. The options will be passed to
    `Phoenix.Component.attr/3`. Most components define a set of default
    modifiers.
  - `class_name_fun` - A 1-arity function that takes a modifier attribute value
    and returns a CSS class name. Defaults to `Doggo.modifier_class_name/1`.
  """

  use Phoenix.Component

  import Doggo.Macros

  component(
    :accordion,
    modifiers: [],
    doc: """
    Renders a set of headings that control the visibility of their content
    sections.
    """,
    usage: """
    ```heex
    <accordion id="dog-breeds">
      <:section title="Golden Retriever">
        <p>
          Friendly, intelligent, great with families. Origin: Scotland. Needs
          regular exercise.
        </p>
      </:section>
      <:section title="Siberian Husky">
        <p>
          Energetic, outgoing, distinctive appearance. Origin: Northeast Asia.
          Loves cold climates.
        </p>
      </:section>
      <:section title="Dachshund">
        <p>
          Playful, stubborn, small size. Origin: Germany. Enjoys sniffing games.
        </p>
      </:section>
    </accordion>
    ```
    """,
    type: :component,
    since: "0.6.0",
    attrs_and_slots:
      quote do
        attr :id, :string, required: true

        attr :expanded, :atom,
          values: [:all, :none, :first],
          default: :all,
          doc: """
          Defines how the accordion sections are initialized.

          - `:all` - All accordion sections are expanded by default.
          - `:none` - All accordion sections are hidden by default.
          - `:first` - Only the first accordion section is expanded by default.
          """

        attr :heading, :string,
          default: "h3",
          values: ["h2", "h3", "h4", "h5", "h6"],
          doc: """
          The heading level for the section title (trigger).
          """

        attr :rest, :global, doc: "Any additional HTML attributes."

        slot :section, required: true do
          attr :title, :string
        end
      end,
    heex:
      quote do
        ~H"""
        <div id={@id} class={[@base_class | @modifier_classes]} {@rest}>
          <div :for={{section, index} <- Enum.with_index(@section, 1)}>
            <.dynamic_tag name={@heading}>
              <button
                id={"#{@id}-trigger-#{index}"}
                type="button"
                aria-expanded={
                  to_string(
                    Doggo.Components.accordion_section_expanded?(index, @expanded)
                  )
                }
                aria-controls={"#{@id}-section-#{index}"}
                phx-click={Doggo.Components.toggle_accordion_section(@id, index)}
              >
                <span><%= section.title %></span>
              </button>
            </.dynamic_tag>
            <div
              id={"#{@id}-section-#{index}"}
              role="region"
              aria-labelledby={"#{@id}-trigger-#{index}"}
              hidden={!Doggo.Components.accordion_section_expanded?(index, @expanded)}
            >
              <%= render_slot(section) %>
            </div>
          </div>
        </div>
        """
      end
  )

  @doc false
  def accordion_section_expanded?(_, :all), do: true
  def accordion_section_expanded?(_, :none), do: false
  def accordion_section_expanded?(1, :first), do: true
  def accordion_section_expanded?(_, :first), do: false

  @doc false
  def toggle_accordion_section(id, index)
      when is_binary(id) and is_integer(index) do
    %Phoenix.LiveView.JS{}
    |> Phoenix.LiveView.JS.toggle_attribute({"aria-expanded", "true", "false"},
      to: "##{id}-trigger-#{index}"
    )
    |> Phoenix.LiveView.JS.toggle_attribute({"hidden", "hidden"},
      to: "##{id}-section-#{index}"
    )
  end

  component(
    :action_bar,
    modifiers: [],
    doc: """
    The action bar offers users quick access to primary actions within the
    application.

    It is typically positioned to float above other content.

    > #### In Development {: .warning}
    >
    > The necessary JavaScript for making this component fully functional and
    > accessible will be added in a future version.
    >
    > **Missing features**
    >
    > - Roving tabindex
    > - Move focus with arrow keys
    """,
    usage: """
    ```heex
    <action_bar>
      <:item label="Edit" on_click={JS.push("edit")}>
        <icon size={:small}><Lucideicons.pencil aria-hidden /></icon>
      </:item>
      <:item label="Move" on_click={JS.push("move")}>
        <icon size={:small}><Lucideicons.move aria-hidden /></icon>
      </:item>
      <:item label="Archive" on_click={JS.push("archive")}>
        <icon size={:small}><Lucideicons.archive aria-hidden /></icon>
      </:item>
      </action_bar>
    ```
    """,
    type: :component,
    since: "0.6.0",
    attrs_and_slots:
      quote do
        attr :rest, :global, doc: "Any additional HTML attributes."

        slot :item, required: true do
          attr :label, :string, required: true
          attr :on_click, JS, required: true
        end
      end,
    heex:
      quote do
        ~H"""
        <div role="toolbar" class={[@base_class | @modifier_classes]} {@rest}>
          <button :for={item <- @item} phx-click={item.on_click} title={item.label}>
            <%= render_slot(item) %>
          </button>
        </div>
        """
      end
  )

  component(
    :badge,
    modifiers: [
      size: [values: ["small", "normal", "medium", "large"], default: "normal"],
      variant: [
        values: [
          nil,
          "primary",
          "secondary",
          "info",
          "success",
          "warning",
          "danger"
        ],
        default: nil
      ]
    ],
    doc: """
    Generates a badge component, typically used for drawing attention to elements
    like notification counts.
    """,
    usage: """
    ```heex
    <badge>8</badge>
    ```
    """,
    type: :component,
    since: "0.6.0",
    attrs_and_slots:
      quote do
        attr :rest, :global, doc: "Any additional HTML attributes."
        slot :inner_block, required: true
      end,
    heex:
      quote do
        ~H"""
        <span class={[@base_class | @modifier_classes]} {@rest}>
          <%= render_slot(@inner_block) %>
        </span>
        """
      end
  )

  component(
    :cluster,
    modifiers: [],
    doc: """
    Use the cluster component to visually group children.

    Common use cases are groups of buttons, or group of tags.
    """,
    usage: """
    ```heex
    <cluster>
      <div>some item</div>
      <div>some other item</div>
    </cluster>
    ```
    """,
    type: :component,
    since: "0.6.0",
    attrs_and_slots:
      quote do
        attr :rest, :global, doc: "Any additional HTML attributes."
        slot :inner_block, required: true
      end,
    heex:
      quote do
        ~H"""
        <div class={[@base_class | @modifier_classes]} {@rest}>
          <%= render_slot(@inner_block) %>
        </div>
        """
      end
  )

  component(
    :tag,
    modifiers: [
      size: [values: ["small", "normal", "medium", "large"], default: "normal"],
      variant: [
        values: [
          nil,
          "primary",
          "secondary",
          "info",
          "success",
          "warning",
          "danger"
        ],
        default: nil
      ],
      shape: [values: [nil, "pill"], default: nil]
    ],
    doc: """
    Renders a tag, typically used for displaying labels, categories, or keywords.
    """,
    usage: """
    ```heex
    <tag>Well-Trained</tag>
    ```

    With icon:

    ```heex
    <tag>
      Puppy
      <icon><Heroicons.edit /></icon>
    </tag>
    ```

    With delete button:

    ```heex
    <tag>
      High Energy
      <button
        phx-click="remove-tag"
        phx-value-tag="high-energy"
        aria-label="Remove tag"
      >
        <icon><Heroicons.x /></icon>
      </button>
    </tag>
    ```
    """,
    type: :component,
    since: "0.6.0",
    attrs_and_slots:
      quote do
        attr :rest, :global, doc: "Any additional HTML attributes."
        slot :inner_block, required: true
      end,
    heex:
      quote do
        ~H"""
        <span class={[@base_class | @modifier_classes]} {@rest}>
          <%= render_slot(@inner_block) %>
        </span>
        """
      end
  )

  component(
    :tree_item,
    base_class: nil,
    modifiers: [],
    doc: """
    Renders a tree item within a `tree/1`.

    This component can be used as a direct child of `tree/1` or within the `items`
    slot of this component.

    > #### In Development {: .warning}
    >
    > The necessary JavaScript for making this component fully functional and
    > accessible will be added in a future version.
    >
    > **Missing featumres**
    >
    > - Expand and collapse nodes
    > - Select nodes
    > - Navigate tree with arrow keys
    """,
    usage: """
    ```heex
    <tree label="Dogs">
      <tree_item>
        Breeds
        <:items>
          <tree_item>Golden Retriever</tree_item>
          <tree_item>Labrador Retriever</tree_item>
        </:items>
      </tree_item>
      <tree_item>
        Characteristics
        <:items>
          <tree_item>Playful</tree_item>
          <tree_item>Loyal</tree_item>
        </:items>
      </tree_item>
    </tree>
    ```

    Icons can be added before the label:

    <tree_item>
      <Heroicon.folder /> Breeds
      <:items>
        <tree_item><Heroicon.document /> Golden Retriever</tree_item>
        <tree_item><Heroicon.document /> Labrador Retriever</tree_item>
      </:items>
    </tree_item>
    """,
    type: :component,
    since: "0.6.0",
    attrs_and_slots:
      quote do
        attr :rest, :global, doc: "Any additional HTML attributes."

        slot :items,
          doc: """
          Slot for children of this item. Place one or more additional `tree_item/1`
          components within this slot, or omit if this is a leaf node.
          """

        slot :inner_block,
          required: true,
          doc: """
          Slot for the item label.
          """
      end,
    heex:
      quote do
        ~H"""
        <li
          class={[@base_class | @modifier_classes]}
          role="treeitem"
          aria-selected="false"
          aria-expanded={@items != [] && "false"}
          {@rest}
        >
          <span><%= render_slot(@inner_block) %></span>
          <ul :if={@items != []} role="group">
            <%= render_slot(@items) %>
          </ul>
        </li>
        """
      end
  )

  @doc false
  def modifier_classes(modifier_names, class_name_fun, assigns) do
    for name <- modifier_names do
      case assigns do
        %{^name => value} when is_binary(value) -> class_name_fun.(value)
        _ -> nil
      end
    end
  end
end
