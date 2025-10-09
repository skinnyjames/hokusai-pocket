require_relative "./mounting/loop_entry"
require_relative "./mounting/mount_entry"
require_relative "./mounting/update_entry"

module Hokusai
  class NodeMounter
    attr_accessor :primary_stack, :secondary_stack
    attr_reader :root

    def initialize(node, klass, secondary_stack = [], previous_target = nil, previous_providers: {})
      @root = klass.new(node: node, providers: previous_providers)

      raise Hokusai::Error.new("Root #{klass} doesn't have a node.  Did you remember to call `super`?") if @root.node.nil?

      @secondary_stack = secondary_stack
      @primary_stack = []

      node.ast.children.each_with_index do |child, index|
        primary_stack << Mounting::MountEntry.new(index, child, root, root, previous_target || root, providers: root.providers)
      end
    end

    def mount(context: nil, providers: {})
      mount_providers = providers.merge(root.providers)

      while entry = primary_stack.shift
        next if entry.virtual?

        if entry.loop?
          entries, secondary_entries = Mounting::LoopEntry.new(entry).register

          self.primary_stack = entries + primary_stack
          self.secondary_stack = secondary_entries + secondary_stack

          next
        end

        if entry.ast.has_if_condition?
          next unless entry.target.send(entry.ast.if.method)
        end

        if entry.slot?
          while siblings = secondary_stack.shift
            next if siblings.empty?

            continue = false

            while sibling_entry = siblings.pop
              # if we encounter a nested slot, we will
              # add the current siblings to the end of the next
              # non-empty slot sibling group
              # and continue processing slots
              if sibling_entry.slot?
                continue = true

                secondary_stack.each_with_index do |previous_siblings, i|
                  next if previous_siblings.empty?

                  secondary_stack[i] = siblings +  previous_siblings
                  siblings.clear

                  break
                end
              else
                primary_stack.unshift sibling_entry.with_block(entry.block)
              end
            end

            next if continue
            break
          end

          next
        end

        entry.mount(context: context, providers: mount_providers) do |child_block|
          new_mount_providers =  mount_providers
                                  .merge(entry.mount_providers)
                                  .merge(entry.block.providers)
                                  .merge(child_block.providers)

          # create a subentry to register event handling and prop passing
          Mounting::UpdateEntry.new(child_block, entry.block, entry.target).register(context: context || entry.ctx, providers: new_mount_providers)

          # Populate the secondary stack with the portal children
          # this stack will be used to populate any slots in the primary_stack
          items = []

          entry.ast.children.each_with_index do |child, child_index|
            child.has_if_condition?

            items << Mounting::MountEntry.new(child_index, child, child_block, entry.parent, entry.target, context: entry.ctx, providers: new_mount_providers)
          end

          secondary_stack.unshift items

          # populate the primary stack with the newly compiled
          # ast from child_block
          primary_items = []

          child_block.node.ast.children.each_with_index do |child, child_index|
            primary_items << Mounting::MountEntry.new(child_index, child, child_block, child_block, context: entry.ctx, providers: new_mount_providers)
          end

          self.primary_stack = primary_items + primary_stack
        end
      end

      root
    end
  end
end