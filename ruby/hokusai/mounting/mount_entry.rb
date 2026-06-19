module Hokusai
  module Mounting
    class MountEntry
      attr_reader :block, :parent, :ast, :target, :index, :ctx

      def initialize(index, ast, block, parent, target = parent, context: nil, providers: {})
        @index = index
        @ast = ast
        @block = block
        @parent = parent
        @target = target
        @providers = providers
        @ctx = context
      end

      def mount_providers
        @providers
      end

      def loop?
        ast.loop?
      end

      def virtual?
        ast.virtual?
      end

      def slot?
        ast.slot?
      end

      def debug
        str = <<~EOF
          #{block.class} | #{ast.type} (#{index})
          #{block.node.ast.children.map(&:type)}
          providers: #{@providers.map {|k,v| k }.join(", ")}
          parent: #{parent.class}
          target: #{target.class}\n\n
        EOF
      end

      def with_block(new_block, supercede_parent: false)
        parent_block = supercede_parent ? block : parent

        MountEntry.new(index, ast, new_block, parent_block, target, context: ctx, providers: mount_providers)
      end

      def mount(context: nil, providers: {})
        klass = ast.dynamic? ? ast.type : target.class.use(ast.type)
        portal = Node.new(ast)

        # compile the ast and get the node
        # NOTE: for templates, we compile the ast before instatiation
        # but for build templates we need the block before the node.
        node = klass.compile(ast.type, portal)
        node.add_styles(target.class)
        node.add_props_from_block(target, context: context || ctx)

        # handle provides / dependency injection
        child_block = klass.new(node: node, providers: providers.merge(mount_providers))
        child_block.node.meta.publisher.add(target, extra: context&.proxies || ctx&.proxies || {}) # todo
        UpdateEntry.new(child_block, block, target).register(context: context || ctx, providers: providers.merge(mount_providers))

        block.node.meta << child_block

        yield child_block

        block.on_mounted if block.respond_to?(:on_mounted) if ast.siblingindex.zero?
      end
    end
  end
end