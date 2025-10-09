require_relative "./publisher"

module Hokusai
  class Meta
    attr_reader :focused, :parent, :target, :updater,
                :props, :publisher

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

    def node_count
      count = children?&.size || 0

      children?&.each do |child|
        count += child.node.meta.node_count
      end

      count
    end

    def get_child?(index)
      return nil if @children.nil?

      get_child(index)
    end

    def children=(values)
      @children = values
    end

    def children?
      return nil if @children.nil?

      @children
    end

    def <<(child)
      children! << child
    end

    def get_child(index)
      children![index]
    end

    def set_child(index, value)
      children![index] = value
    end

    def children!
      @children ||= []
    end

    def props!
      @props ||= {}
    end

    def get_prop?(name)
      return nil if @props.nil?

      get_prop(name)
    end

    def set_prop(name, value)
      @props ||= {}

      @props[name] = value
    end

    def get_prop(name)
      @props ||= {}

      @props[name]
    end

    def focus
      @focused = true

      children?&.each do |child|
        child.node.meta.focus
      end
    end

    def blur
      @focused = false

      children?&.each do |child|
        child.node.meta.blur
      end
    end

    def on_update(target, &block)
      @target = target
      @updater = block
    end

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

    def child_delete(index)
      if child = children![index]
        child.before_destroy if child.respond_to?(:before_destroy)
        child.node.destroy

        children!.delete_at(index)
      end
    end
  end
end