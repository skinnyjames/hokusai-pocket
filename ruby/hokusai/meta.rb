require_relative "./publisher"

module Hokusai
  # Public: coordinates block children, including updates and event emitting
  # 
  class Meta
    attr_reader :focused, :parent, :target, :updater,
                :props, :publisher

    # Internal: a Hokusai::Commands cache
    def commands
      @commands ||= Commands.new
    end

    def initialize
      @focused = false
      @parent = nil
      @target = nil
      @updater = nil
      @props = nil
      @publisher = Publisher.new
      @children = nil
    end

    # Internal: How many descedants does this node have?
    # 
    # returns Integer
    def node_count
      count = children?&.size || 0

      children?&.each do |child|
        count += child.node.meta.node_count
      end

      count
    end

    # Internal: Gets a child by index
    # 
    # index - the index of the child block (Integer)
    # 
    # Returns Hokusai::Block or nil
    def get_child?(index)
      return nil if @children.nil?

      get_child(index)
    end

    # Internal: Sets children
    # 
    # values - array of Hokusai::Block
    # 
    # Returns nothing
    def children=(values)
      @children = values
    end

    def children?
      return nil if @children.nil?

      @children
    end

    # Internal: Append child
    # 
    # child - a Hokusai::Block
    def <<(child)
      children! << child
    end
    
    # Internal: Gets a child by index.  Creates an empty array if no children found.
    # 
    # index - the index of the child block (Integer)
    # 
    # Returns Hokusai::Block
    def get_child(index)
      children![index]
    end

    # Public: Set a child by index. Creates an empty array if no children found.
    # 
    # index - the index of child block (Integer)
    # value - a Hokusai::Block
    # 
    # Returns nothing
    def set_child(index, value)
      children![index] = value
    end


    # Internal: Returns children or empty array
    def children!
      @children ||= []
    end

    # Internal: Returns props or empty hash
    def props!
      @props ||= {}
    end

    # Public: Get a prop value by it's name
    # 
    # name - name of prop (Symbol)
    # 
    # Returns Object or Nil if no props found
    def get_prop?(name)
      return nil if @props.nil?

      get_prop(name)
    end

    # Public: Set a prop value
    # 
    # name - name of prop (Symbol)
    # value - value to set prop to 
    def set_prop(name, value)
      @props ||= {}

      @props[name] = value
    end

    # Public: Get a prop value by it's name
    # 
    # name - name of prop (Symbol)
    # 
    # Returns Object or nil if prop not found
    def get_prop(name)
      @props ||= {}

      @props[name]
    end

    # Public: Set this node and chlidren to focused
    def focus
      @focused = true

      children?&.each do |child|
        child.node.meta.focus
      end
    end

    # Public: Unfocus this node and children
    def blur
      @focused = false

      children?&.each do |child|
        child.node.meta.blur
      end
    end

    # Internal: Set on update callback.  Used by [Hokusai::NodeMounter](/api/Hokusai/NodeMounter) and the like
    # 
    # target - a Hokusai::Block that this node should emit events to
    # block - an updater callback
    def on_update(target, &block)
      @target = target
      @updater = block
    end

    # Internal: Updates the props on (value), calling lifecycle callbacks if they exist.
    # 
    # value - a Hokusai::Block
    def update(block)
      if target_block = target
        if updater_block = updater
          block.before_updated if block.respond_to?(:before_updated)

          updater_block.call(block, target_block, target_block)

          # reset all styles
          block.after_updated if block.respond_to?(:after_updated)
        end
      end
    end

    
    def has_ast?(ast, index, elsy = false)
      if elsy
        if portal = children![index]&.node&.portal
          return portal.ast.object_id == ast.object_id
        end
      else
        if portal = children![index]&.node&.portal&.portal
          return portal.ast.object_id == ast.object_id
        end
      end

      false
    end

    # Internal: Delete a child by index, calling lifecycle callbacks if they exist.
    # 
    # index - the index of the child
    # 
    # Returns nothing
    def child_delete(index)
      if child = children![index]
        child.before_destroy if child.respond_to?(:before_destroy)
        child.node.destroy

        children!.delete_at(index)
      end
    end
  end
end