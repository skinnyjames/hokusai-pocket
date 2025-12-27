module Hokusai
  module Mounting
    class UpdateEntry
      attr_reader :block, :parent, :target

      def initialize(block, parent, target)
        @block = block
        @parent = parent
        @target = target
      end

      def meta
        block.node.meta
      end

      def register(context: nil, providers: {})
        meta.on_update(target) do |ublock, uparent, utarget|
          if portal = ublock.node.portal
            portal.ast.children.each_with_index do |child, index|
              next unless child.has_if_condition?

              child_present = ->(child, elsy) do
                meta.has_ast?(child, index, elsy)
              end 

              if child.if.args.size > 0
                visible = utarget.send(child.if.method, context: context)
              else
                visible = utarget.send(child.if.method)
              end

              child_block_klass = target.class.use(child.type)

              if !!visible
                if child.else_condition_active?
                  meta.child_delete(index) if child_present.call(child, false)
                  child.else_active = false
                end

                unless child_present.call(child, true)
                  portal = Node.new(child, Node.new(child))
                  node = child_block_klass.compile("root", portal)
                  node.add_styles(target.class)
                  node.add_props_from_block(target, context: context)
                  node.meta.publisher.add(target)

                  stack = []
                  child.children.each_with_index do |ast, ast_index|
                    stack << MountEntry.new(ast_index, ast, ublock, uparent, utarget, providers: providers)
                  end

                  child_block = NodeMounter.new(node, child_block_klass, [stack], previous_providers: providers).mount(context: context, providers: providers)

                  UpdateEntry.new(child_block, block, target).register(context: context, providers: providers)
                  meta.children!.insert(index, child_block)

                  child_block.send(:before_updated) if child_block.respond_to?(:before_updated)
                  Hokusai.update(child_block)
                  child.else_active = false
                end
              elsif !visible
                if !child.has_else_condition? || (child.has_else_condition? && !child.else_condition_active?)
                  if (child_present.call(child, true))
                    meta.child_delete(index)
                  end
                end

                if child.has_else_condition? && !child.else_condition_active?
                  portal = Node.new(child.else_ast, Node.new(child))
                  else_child_block_klass = target.class.use(child.else_ast.type)

                  node = else_child_block_klass.compile(child.else_ast.type, portal)
                  node.add_styles(utarget.class)
                  node.add_props_from_block(utarget, context: context)
                  node.meta.publisher.add(utarget)
                  
                  stack = []
                  child.else_ast.children.each_with_index do |ast, ast_index|
                    stack << MountEntry.new(ast_index, ast, ublock, uparent, utarget, providers: providers)
                  end

                  child_block = NodeMounter.new(node, else_child_block_klass, [stack], previous_providers: providers).mount(context: context, providers: providers)
                  UpdateEntry.new(child_block, block, utarget).register(context: context, providers: providers)
                  meta.children!.insert(index, child_block)
                  child_block.send(:before_updated) if child_block.respond_to?(:before_updated)
                  
                  Hokusai.update(child_block)
                  child.else_active = true
                end
              end
            end
          end

          ublock.send(:before_updated) if ublock.respond_to?(:before_updated)
          ublock.node.add_styles(utarget.class)
          ublock.node.add_props_from_block(utarget, context: context)
          ublock.send(:after_updated) if ublock.respond_to?(:after_updated)
        end
      end
    end
  end
end