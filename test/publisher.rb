class PublisherTest < Hokusai::Test
  let(:mock) do
    ->(&block) do
      klass = Class.new do
        attr_reader :state, :publisher
        def initialize
          @state = []
          @publisher = Hokusai::Publisher.new
        end

        def target(name)
          @state << name
        end
      end

      block.call klass.new
    end
  end

  test "publishes events from a child node to it's parent" do
    mock.call do |parent|
      mock.call do |child|
        child.publisher.add(parent)
        child.publisher.notify(:target, "one")
        child.publisher.notify(:target, "two")
      end

      mock.call do |child|
        child.publisher.add(parent)
        child.publisher.notify(:target, "three")
      end

      expect(parent.state).to eql(["one", "two", "three"])
    end
  end

end