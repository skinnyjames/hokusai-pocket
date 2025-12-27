class SlotsSpec < Hokusai::Test
   let(:virtual) do
    klass = Class.new(Hokusai::Block) do
      template <<~EOF
      [template]
        virtual
      EOF
    end

    klass
  end

  let(:slotted) do
    virtual_klass = virtual

    klass = Class.new(Hokusai::Block) do
      template <<~EOF
      [template]
        sibling1
        slot
        sibling2
      EOF

      uses(sibling1: virtual_klass, sibling2: virtual_klass)
    end

    klass
  end

   
  let(:root_klass) do
    slotted_klass = slotted
    virtual_klass = virtual
    klass = Class.new(Hokusai::Block) do
      template <<~EOF
      [template]
        slotted
          between { :prop="id" @event="root_event" }
      EOF

      uses(slotted: slotted_klass, between: virtual_klass)
  
      attr_accessor :id
  
      def root_event(value)
        self.id += value
      end
  
      def initialize(**args)
        @id = 3
  
        super
      end
    end

    klass
  end


  test "mounts portaled children inside slot" do
    root = root_klass.mount
    expect(root.children.size).to eql(1)

    child = root.children.first
    expect(child.node.type).to eql('slotted') 

    sibling_types = child.children.map {|c| c.node.type }

    expect(sibling_types).to eql(["sibling1", "between", "sibling2"])
  end

  test "slotted blocks have access to their parent data and events" do
    root = root_klass.mount
    between = root.children.first.children[1]
    expect(between.node.meta.props[:prop]).to eql(3)
    between.emit("event", 2)
    expect(root.id).to eql(5)
  end

  let(:slot) do
    klass = Class.new(Hokusai::Block) do
      template <<~EOF
      [template]
        slot
      EOF
    end

    klass
  end

  let(:nested) do
    slot_klass = slot
    virtual_klass = virtual
    klass = Class.new(Hokusai::Block) do
      template <<~EOF
      [template]
        empty
          slot
          virtual
      EOF

      uses(empty: slot_klass, virtual: virtual_klass)
    end

    klass
  end

  let(:root_klass2) do
    nested_klass = nested
    virtual_klass = virtual
    klass = Class.new(Hokusai::Block) do
      template <<~EOF
      [template]
        first { prop="first"}
        nested
          second { prop="second" }
        third { prop="third" }
      EOF

      uses(first: virtual_klass, nested: nested_klass, second: virtual_klass, third: virtual_klass)
    end

    klass
  end

  test "slots can be nested" do
    root = root_klass2.mount

    expect(root.children.size).to eql(3)
    empty = root.children[1].children.first

    expect(empty.node.type).to eql("empty")
    
    second = empty.children.first
    expect(second.node.type).to eql("second")

    expect(second.node.meta.props[:prop]).to eql("second")
    
    children = root.children
    expect(children.first.node.meta.props[:prop]).to eql("first")

    expect(children.last.node.meta.props[:prop]).to eql("third")
  end
end