module Hokusai::Automation
  class Selector
    attr_reader :node, :id, :class_list

    def initialize(node, id, classes)
      @node = node
      @id = id
      @class_list = classes || []
    end

    def matches(block)
      if portal = block.node.portal
        ast = portal.ast

        matches = [[ast.type, node], [ast.id, id]].reduce(true) do |memo, (ast_property, target)|
          next memo if target.nil?

          target == ast_property && memo
        end

        return (class_list & ast.classes) == class_list && matches
      end

      false
    end

    def to_s(str = "")
      classes_string = nil

      unless class_list.empty?
        classes_string = ".#{class_list.join(".")}"

        str << "#{node || ""}##{id || ""}#{classes_string || ""}"
      end

      str
    end
  end
end