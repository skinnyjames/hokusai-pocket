module Setup
  def counter
    @counter ||= begin
      Class.new do
        attr_reader :count

        def initialize
          @count = 0
        end

        def increment
          @count += 1
        end

        def decrement
          @count -= 1
        end
      end
    end
  end

  def provider
    @provider ||= begin
      counter_klass = counter
      Class.new(Hokusai::Block) do
        template <<~EOF
        [template]
          slot
        EOF

        provide :provision, counter_klass.new

        def state
          self.class.provides[:provision]
        end
      end
    end
  end

  def inject
    @inject ||= begin
      Class.new(Hokusai::Block) do
        template <<~EOF
        [template]
          virtual
        EOF

        inject :provision

        def increment
          provision.increment
        end
      end
    end
  end
end

class ProviderTest < Hokusai::Test
  include Setup

  let(:container) do
    provider_klass = provider
    inject_klass = inject
    c = Class.new(Hokusai::Block) do
      template <<~EOF
      [template]
        vblock
          provision
            vblock
              inject
            vblock
              empty
          vblock
            control
      EOF

      uses(
        vblock: Hokusai::Blocks::Vblock,
        provision: provider_klass,
        inject: inject_klass,
        control: inject_klass,
        empty: Hokusai::Blocks::Empty
      )
    end

    c.mount
  end

  test "provisions can be injected into descendants" do
    injected = get_block_by_type(container, "inject")
    provided = get_block_by_type(container, "provision")

    expect(injected.provision.count).to eql(0)
    injected.provision.increment

    expect(injected.provision.count).to eql(1)
    expect(provided.state.count).to eql(1)
  end

  test "provisions aren't injected into non-descendants" do
    injected = get_block_by_type(container, "control")
    
    expect(injected.provision).to eql(nil)
  end
end

class ProviderLoopTest < Hokusai::Test
  include Setup

  let(:loop_container) do
    provider_klass = provider
    inject_klass = inject
    c = Class.new(Hokusai::Block) do
      template <<~EOF
      [template]
        vblock
          provision
            [for="item in list"]
              vblock
                inject { :key="item" }
          control
      EOF

      uses(
        vblock: Hokusai::Blocks::Vblock,
        control: inject_klass,
        inject: inject_klass,
        provision: provider_klass
      )

      def list
        @list ||= [1,2,3,4]
      end
    end

    c.mount
  end

  test "provisions extend to loop children" do
    injected = get_blocks_by_type(loop_container, "inject")
    provided = get_block_by_type(loop_container, "provision")
    control = get_block_by_type(loop_container, "control")

    expect(injected.first.provision.count).to eql(0)
    injected.first.provision.increment

    injected.each do |child|
      expect(child.provision.count).to eql(1)
    end

    expect(control.provision).to be(nil)
    expect(provided.state.count).to eql(1)
  end
end

class ProviderConditionalTest < Hokusai::Test
  include Setup

  let(:conditional_container) do
    provider_klass = provider
    inject_klass = inject
    c = Class.new(Hokusai::Block) do
      template <<~EOF
      [template]
        container
          provision
            [if="show"]
              vblock
                inject
            [else]
              vblock
                injectelse
          control
      EOF

      uses(
        container: Hokusai::Blocks::Vblock,
        vblock: Hokusai::Blocks::Vblock,
        control: inject_klass,
        inject: inject_klass,
        injectelse: inject_klass,
        provision: provider_klass
      )

      attr_accessor :show

      def initialize(**args)
        @show = false

        super
      end

      def toggle
        self.show = !show
      end
    end

    c.mount
  end

  test "provisions extend to conditional children", tags: [:focus] do
    conditional_container.toggle
    Hokusai.update(conditional_container)

    injected = get_block_by_type(conditional_container, "inject")
    provided = get_block_by_type(conditional_container, "provision")
    control = get_block_by_type(conditional_container, "control")

    expect(injected).not_to be(nil), "inject is nil"
    expect(injected.provision.count).to eql(0)
    injected.provision.increment

    expect(injected.provision.count).to eql(1)
    expect(provided.state.count).to eql(1)
    expect(control.provision).to be(nil)
    
    conditional_container.toggle
    Hokusai.update(conditional_container)

    inject_else = get_block_by_type(conditional_container, "injectelse")
    expect(inject_else.provision).not_to be(nil)
    expect(inject_else.provision.count).to eql(1)
    inject_else.provision.increment

    expect(provided.state.count).to eql(2)
  end
end

class ProviderLoopConditionTest < Hokusai::Test
  include Setup

  let(:loop_if_container) do
    provider_klass = provider
    inject_klass = inject

    c = Class.new(Hokusai::Block) do
      template <<~EOF
      [template]
        container
          provision
            [for="value in values"]
              vblock { :key="value" }
                [if="show"]
                  vblock
                    inject
                [else]
                  vblock
                    injectelse
          control
      EOF

      uses(
        container: Hokusai::Blocks::Vblock,
        vblock: Hokusai::Blocks::Vblock,
        control: inject_klass,
        inject: inject_klass,
        injectelse: inject_klass,
        provision: provider_klass
      )

      attr_accessor :show

      def initialize(**args)
        @show = false

        super
      end

      def values
        [1,2,3,4,5]
      end

      def toggle
        self.show = !show
      end
    end

    c.mount
  end

  test "provisions extend to conditional children in loops" do
    Hokusai.update(loop_if_container)

    loop_if_container.toggle
    Hokusai.update(loop_if_container)

    injecteds = get_blocks_by_type(loop_if_container, "inject")
    provided = get_block_by_type(loop_if_container, "provision")
    control = get_block_by_type(loop_if_container, "control")
    
    injecteds.each do |injected|
      expect(injected.provision.count).to eql(0)
    end

    injecteds.first.provision.increment

    injecteds.each do |injected|
      expect(injected.provision.count).to eql(1)
    end

    expect(provided.state.count).to eql(1)
    expect(control.provision).to be(nil)

    loop_if_container.toggle
    Hokusai.update(loop_if_container)

    inject_elses = get_blocks_by_type(loop_if_container, "injectelse")
    
    inject_elses.each do |inject_else|
      expect(inject_else.provision).not_to be(nil)
      expect(inject_else.provision.count).to eql(1)
    end

    inject_elses.first.provision.increment

    expect(provided.state.count).to eql(2)
  end
end