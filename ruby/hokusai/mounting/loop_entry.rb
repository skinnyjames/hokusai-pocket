require_relative "../diff"

module Hokusai
  module Mounting
    class LoopContext
      attr_reader :table
      def initialize
        @table = {}
      end

      def add_entry(var, value)
        table[var] = value
      end

      def send_target(target, func)
        args = func.args.map do |arg|
          table[arg]
        end

        target.send(func.method, *args)
      end
    end

    class LoopEntry
      INDEX_KEY = "index".freeze

      def initialize(mount_entry)
        @entry = mount_entry
      end

      def ast
        @entry.ast
      end

      def block
        @entry.block
      end
      
      def target
        @entry.target
      end

      def parent
        @entry.parent
      end

      def mount_providers
        @entry.mount_providers
      end

      def register
        child_block_class = target.class.use(ast.type)
        values = target.send(ast.loop.method)

        unless values.is_a?(Enumerable)
          raise Hokusai::Error.new("Loop directive `#{ast.loop.method}` on #{target.class} must return an Enumerable")
        end

        entries_to_return = []
        secondary_entries = []

        values.each_with_index do |value, index|
          ctx = LoopContext.new
          ctx.add_entry(ast.loop.var, value)
          ctx.add_entry(INDEX_KEY, index)

          if ast.has_if_condition?
            if ast.if.args.size > 0
              ctx.send_target(target, target.if)
            else
              condition = target.send(ast.if.method)
            end

            next if condition
          end

          portal = Node.new(ast)
          node = child_block_class.compile(ast.type, portal)
          child_block = child_block_class.new(node: node, providers: mount_providers)
          child_block.node.add_styles(target.class)
          child_block.node.add_props_from_block(target, context: ctx)
          child_block.node.meta.set_prop(ast.loop.var.to_sym, value)
          child_block.node.meta.publisher.add(target)

          UpdateEntry.new(child_block, block, target).register(context: ctx, providers: mount_providers.merge(child_block.providers))

          block.node.meta << child_block

          node.ast.children.each_with_index do |child, idx|
            entries_to_return << MountEntry.new(index, child, child_block, child_block, child_block, context: nil, providers: mount_providers.merge(child_block.providers))
          end

          siblings = []
          portal.ast.children.each_with_index do |child, idx|
            siblings << MountEntry.new(idx, child, child_block, child_block, target, context: ctx, providers: mount_providers.merge(child_block.providers))
          end

          secondary_entries << siblings
        end

        update_loop

        [entries_to_return, secondary_entries]
      end

      def update_loop
        block.node.meta.on_update(target) do |ublock, uparent, utarget|
          values = utarget.send(ast.loop.method)

          unless values.is_a?(Enumerable)
            raise Hokusai::Error.new("Loop directive `#{ast.loop.method}` on #{target.class} must return an Enumerable")
          end

          key_prop = ast.props["key"]

          raise Hokusai::Error.new("Loop children must have a :key method defined") if key_prop.nil?

          key_ctx = LoopContext.new

          new_values = []

          index_key = "index".freeze
          values.each_with_index do |value, index|
            key_ctx.add_entry(ast.loop.var, value)
            key_ctx.add_entry(index_key, index)

            if key_prop.value.args.size > 0
              key = key_ctx.send_target(utarget, key_prop.value)
            elsif key_ctx.table[key_prop.value.method]
              key = key_ctx.table[key_prop.value.method]
            else
              key = utarget.send(key_prop.value.method)
            end

            new_values << [key, value]
          end

          previous_values = []
          children = []
          loop_var = ast.loop.var.to_sym

          ublock.children?&.each do |child|
            if key = child.node.meta.get_prop(:key)
              raise Hokusai::Error.new("Loop children must use :key field") unless key

              previous_values << [key, child.node.meta.get_prop(loop_var)]
            end

            children << child
          end

          if new_values == previous_values
            next
          end

          Diff.new(previous_values, new_values).patch do |patch|
            case patch
            when UpdatePatch
              ctx = LoopContext.new
              ctx.add_entry("index", patch.target)
              ctx.add_entry(ast.loop.var, patch.value)
              children[patch.target].node.add_styles(target.class)
              children[patch.target].node.add_props_from_block(target, context: ctx)

              UpdateEntry.new(children[patch.target], uparent, utarget).register(context: ctx)
            when MovePatch
              if patch.delete
                from = children[patch.from]
                children[patch.to] = from
                children[patch.from].send(:before_destroy) if children[patch.from].respond_to? :before_destroy
                children[patch.from].node.destroy
                children[patch.from] = nil
              else
                from = children[patch.from]
                to = children[patch.to]

                children[patch.to] = from
                children[patch.from] = to
              end

              ctx = LoopContext.new
              ctx.add_entry(INDEX_KEY, patch.to)
              children[patch.to].node.meta.props.each do |k, v|
                ctx.add_entry(k.to_s, v)
              end

              children[patch.to].node.add_styles(target.class)
              children[patch.to].node.add_props_from_block(target, context: ctx)
            when InsertPatch
              target_ast = ast
              ctx = LoopContext.new
              ctx.add_entry(INDEX_KEY, patch.target)
              ctx.add_entry(ast.loop.var, patch.value)

              if ast.has_if_condition?
                if ast.if.args.size > 0
                  condition = ctx.send_target(target, ast.if.method)
                else
                  condition = target.send(ast.if.method)
                end

                if !condition && ast.has_else_condition?
                  target_ast = ast.else_ast
                elsif !condition
                  children[patch.target].send(:before_destroy) if children[patch.target].respond_to? :before_destroy
                  children[patch.target].node.destroy
                  children[patch.target] = nil
                  next
                end
              end

              child_block_class = utarget.class.use(target_ast.type)
              portal = Node.new(ast)
              node = child_block_class.compile(target_ast.type, portal)
              node.add_props_from_block(target, context: ctx)
              child_block = NodeMounter.new(node, child_block_class).mount(context: nil, providers: mount_providers.merge(ublock.providers))
              child_block.node.add_styles(target.class)
              child_block.node.meta.publisher.add(target)

              if patch.delete
                children[patch.target] = child_block
              else
                children.insert(patch.target, child_block)
              end
            when DeletePatch
              children[patch.target].send(:before_destroy) if children[patch.target].respond_to? :before_destroy
              children[patch.target].node.destroy
              children[patch.target] = nil
              # TODO: update rest of block props
            end
          end

          ublock.node.meta.children = children.reject(&:nil?)
        end
      end
    end
  end
end
