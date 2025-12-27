class BlockTest < Hokusai::Test
  let(:child_klass) do
    Class.new(Hokusai::Block) do
      template <<~EOF
        [template]
          virtual
      EOF
      computed! :echo

      def self.foobar
        nil
      end

      def hello
        @state += 1

        emit("get", @state)
      end

      def initialize(**args)
        @state = 0

        super(**args)
      end
    end
  end

  let(:parent) do
    child_block = child_klass
    klass = Class.new(Hokusai::Block) do
      template <<~EOF
        [template]
          child { :echo="total" @get="get_it" }
      EOF

      attr_reader :state, :total, :mounted

      uses(child: child_block)

      def get_it(count)
        @state += count
        @total = "total: #{state}"
      end

      def on_mounted
        @mounted = true
      end

      def initialize(**args)
        @state = 0
        @total = "total: #{state}"
        @mounted = false

        super(**args)
      end
    end

    klass.mount
  end

  let(:child) do
    parent.children.first
  end

  test "mounts blocks together" do
    expect(parent.children.size).to eql(1)
    expect(child.respond_to?(:hello)).to be(true)
  end

  test "blocks have a node and portal node" do
    expect(parent.node.type).to eql("root")
    expect(child.node.portal.type).to eql("child")
  end

  test "mounts props into children" do
    expect(child.echo).to eql("total: 0")
  end

  test "emits events to the parent" do
    child.emit("get", 1)

    expect(parent.state).to eql(1)
  end

  test "raises when an emit is missing a param" do
    begin
      child.emit("get)")
    rescue ex
      expect(ex.class).to eql(ArgumentError)
    end
  end

  test "does not raise when an emtest is not subscribe to" do
    expect { child.emit("foobarrr", 1,23) }.not_to raise_error
  end

  test "updates child props with new state" do
    child.emit("get", 1)
    expect(child.echo).to eql("total: 0")

    Hokusai.update(parent)
    expect(child.echo).to eql("total: 1")
  end

  test "returns a Hokusai::Block by a key" do
    expect(parent.class.use("child").respond_to?(:foobar)).to be(true)
  end

  test "triggers when the block is mounted" do
    expect(parent.mounted).to be(true)
  end
end