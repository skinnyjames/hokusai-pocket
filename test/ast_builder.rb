class AstBuilderTest < Hokusai::Test
  let(:klass) do
    Class.new(Hokusai::Block) do
      style <<~EOF
      [style]
      test { 
        background: rgb(22,22,22);
        width: 50.0;
        height: 200.0;
      }
      EOF

      template do
        child(Hokusai::Blocks::Vblock) do
          merge_styles "test"

          child(Hokusai::Blocks::Rect) do
            static :width, "2323.0"
          end

          each_child(Hokusai::Blocks::Hblock, :list) do |item|
            prop :key do
              "yo-#{item.value}"
            end

            prop :background do
              item.value
            end

            child(Hokusai::Blocks::Vblock) do
              prop :radius do 
                "32 #{item.value}"
              end
            end

            on(:foo) do
              puts "deleting item.value #{item.value}"
              @list.reject! { |f| f == item.value }
            end
          end

          child(Hokusai::Blocks::Rect) do
            static :width, "2323.0"
          end
        end
      end

      def list
        @list ||= %w[one two three]
      end

      def foobar
        Hokusai::Color.new(222,22,21)
      end

      def hello
        [{color: "22,22,22"}, {color: "44,44,44"}]
      end
    end
  end

  test "loops work in between children" do 
    obj = klass.mount
    blocks = get_blocks_by_type(obj, "Hokusai::Blocks::Hblock")
    expect(obj.children.first.children.size).to eql(5)
    expect(blocks.size).to eql(3)
    
    Hokusai.update(obj)

    blocks = get_blocks_by_type(obj, "Hokusai::Blocks::Hblock")
    expect(blocks.size).to eql(3)

    %w[one two three].each_with_index do |item, i|
      expect(blocks[i].node.meta.get_prop(:background)).to eql(item)
    end

    blocks[2].emit(:foo)
    
    Hokusai.update(obj)

    blocks = get_blocks_by_type(obj, "Hokusai::Blocks::Hblock")
    expect(blocks.size).to eql(2)
    expect(obj.children.first.children.size).to eql(4)
    %w[one two].each_with_index do |item, i|
      expect(blocks[i].node.meta.get_prop(:background)).to eql(item)
    end
  end

  let(:if_klass) do
    Class.new(Hokusai::Block) do
      attr_accessor :sean

      template do
        child(Hokusai::Blocks::Vblock) do
          child(Hokusai::Blocks::Scrollbar) do
            show_if do
              @sean
            end

            on(:foo) do
              @sean = !@sean
            end
          end
        end
      end

      def initialize(**args)
        @sean = true

        super
      end
    end
  end

  test "conditions work on a nested node" do
    obj = if_klass.mount
    robj = obj.children.first
    expect(robj.children.size).to eql(1)

    robj.children.first.emit(:foo)

    Hokusai.update(obj)
    robj = obj.children.first

    expect(robj.children.size).to eql(0)
  end


  let(:top_if_klass) do
    Class.new(Hokusai::Block) do
      attr_accessor :sean

      template do
        child(Hokusai::Blocks::Scrollbar) do
          show_if do
            @sean
          end

          on(:foo) do
            @sean = !@sean
          end
        end
      end

      def initialize(**args)
        @sean = true

        super
      end
    end
  end

  # test "conditions work on the top level (experimental)" do
  #   obj = top_if_klass.mount
  #   expect(obj.children.size).to eql(1)

  #   obj.children.first.emit(:foo)

  #   Hokusai.update(obj)

  #   expect(obj.children.size).to eql(0)
  # end
end