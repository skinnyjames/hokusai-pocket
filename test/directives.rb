module BlockDirectivesSetup
  def virtual
    @virtual ||= begin
      klass = Class.new(Hokusai::Block) do
        template <<~EOF
        [template]
          virtual
        EOF
      end

      klass
    end
  end

  def slotted
    @slotted ||= begin
      klass = Class.new(Hokusai::Block) do
        template <<~EOF
        [template]
          slot
        EOF
      end

      klass
    end
  end
end

class BlockDirectivesTest < Hokusai::Test
  include BlockDirectivesSetup

  let(:condition1) do
    virtual_klass = virtual
    klass = Class.new(Hokusai::Block) do
      template <<~EOF
      [template]
        type { content="1" }
        slot
      EOF

      uses(type: virtual_klass)
    end

    klass
  end

  let(:condition2) do
    virtual_klass = virtual
    klass = Class.new(Hokusai::Block) do
      template <<~EOF
      [template]
        type { content="2" }
        slot
      EOF

      uses(type: virtual_klass)
    end

    klass
  end

  let(:branch) do
    virtual_klass = virtual
    cond1 = condition1
    cond2 = condition2
    slot = slotted
    klass = Class.new(Hokusai::Block) do
      template <<~EOF
      [template]
        slotted
          [if="state"]
            cond1
              control1
          [else]
            cond2
              control2
          control
      EOF

      uses(
        slotted: slot,
        cond1: cond1,
        cond2: cond2,
        control: virtual_klass,
        control1: virtual_klass,
        control2: virtual_klass
      )

      attr_accessor :state

      def initialize(**props)
        @state = true

        super
      end
    end
  end

  let (:content) do
    ->(root) do
      root
        .children[0]
        .children[0]
        .children[0]
        .node
        .meta
        .get_prop(:content)
    end
  end

  let (:portal_type) do
    ->(root) do
      root
        .children[0]
        .children[0]
        .children[1]
        .node
        .type
    end
  end

  test "simple condition" do
    root = branch.mount
    expect(content.call(root)).to eql("1")
    
    root.state = false
    Hokusai.update(root)
    expect(content.call(root)).to eql("2")
  end

  test "switches back and forth" do
    root = branch.mount

    expect(content.call(root)).to eql("1")
    expect(root.children[0].children[-1].node.type).to eql("control")

    root.state = false
    Hokusai.update(root)

    expect(content.call(root)).to eql("2")
    expect(root.children[0].children[-1].node.type).to eql("control")

    root.state = true
    Hokusai.update(root)

    expect(content.call(root)).to eql("1")
    expect(root.children[0].children[-1].node.type).to eql("control")
  end

  test "mounts portaled children into the slot" do
    root = branch.mount

    expect(portal_type.call(root)).to eql("control1")

    root.state = false
    Hokusai.update(root)

    expect(portal_type.call(root)).to eql("control2")
  end
end

class BlockLoopDirectiveTest < Hokusai::Test
  include BlockDirectivesSetup
  let(:cell) do
    virtual_klass = virtual
    klass = Class.new(Hokusai::Block) do
      template <<~EOF
      [template]
        empty { :content="value" }
      EOF

      computed! :value
      
      uses(empty: virtual_klass)
    end

    klass
  end

  let(:column) do
    cell_klass = cell
    slotted_klass = slotted

    klass = Class.new(Hokusai::Block) do
      template <<~EOF
      [template]
        slotted
          [for="value in columns"]
            cell { :value="value" }
      EOF
      computed! :row_index

      uses(cell: cell_klass, slotted: slotted_klass)

      def columns
        %w[A B C D].map { |letter| "#{letter}#{row_index}" }
      end
    end

    klass
  end

  let(:csv) do
    column_klass = column
    slotted_klass = slotted


    klass = Class.new(Hokusai::Block) do
      template <<~EOF
      [template]
        slotted
          [for="row in rows"]
            column { :row_index="row" }          
      EOF

      uses(slotted: slotted_klass, column: column_klass)

      def rows
        %w[1 2 3 4]
      end
    end

    klass
  end

  let(:list_item) do
    virtual_klass = virtual

    klass = Class.new(Hokusai::Block) do
      template <<~EOF
      [template]
        empty
      EOF

      attr_accessor :state

      uses(empty: virtual_klass)

      computed! :item

      def initialize(**args)
        @state = "hello"

        super
      end
    end

    klass
  end

  let(:list) do
    list_item_klass = list_item
    slotted_klass = slotted

    klass = Class.new(Hokusai::Block) do
      template <<~EOF
      [template]
        slotted
          [for="item in list"]
            list_item { :item="item" :key="key(item, index)" }
      EOF

      attr_accessor :limit

      uses(slotted: slotted_klass, list_item: list_item_klass)

      def list
        (0...limit).to_a
      end

      def key(item, index)
        "#{item}-#{index}"
      end

      def initialize(**args)
        @limit = 5

        super
      end
    end

    klass
  end

  test "mounts nested loops" do
    root = csv.mount
    
    rows = %w[1 2 3 4]
    cols = %w[A B C D]

    rows.each_with_index do |row, ridx|
      actual_rows = root.children[0].children
      expect(actual_rows.size).to eql(4)

      actual_row = actual_rows[ridx]
      expect(actual_row.row_index).to eql(row)

      actual_columns = actual_row.children[0].children
      expect(actual_columns.size).to eql(4)

      cols.each_with_index do |col, cidx|
        expect(actual_columns[cidx].value).to eql("#{col}#{row}")
      end
    end
  end

  test "diffs so that unchanged blocks are not remounted" do
    root = list.mount
    children = root.children[0].children
    expect(children.size).to eql(5)

    children[0].state = "1"
    children[1].state = "2"
    children[2].state = "3"
    children[3].state = "4"
    children[4].state = "5"

    root.limit = 2
    Hokusai.update(root)
    expect(root.children[0].children.size).to eql(2)


    root.limit = 3
    Hokusai.update(root)
    expect(root.children[0].children.size).to eql(3)

    updated_children = root.children[0].children
    expect(updated_children[0].state).to eql("1")
    expect(updated_children[1].state).to eql("2")
    expect(updated_children[2].state).to eql("hello")
  end
end