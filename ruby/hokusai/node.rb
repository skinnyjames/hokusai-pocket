# frozen_string_literal: true

require_relative "./node_mounter"
require_relative "./meta"

module Hokusai
  class Node
    attr_reader :ast, :node, :uuid, :meta, :portal

    def self.parse(template, name = "root", parent = nil)
      ast = Ast.parse(template, name)

      new(ast, parent)
    end

    def slot?
      ast.slot?
    end

    def type
      ast.type
    end

    def event(name)
      ast.event(name)
    end

    def initialize(ast, portal = nil)
      @ast = ast
      @portal = portal
      # @uuid = SecureRandom.hex(6).freeze
      @meta = Meta.new
    end

    def mount(klass)
      NodeMounter.new(self, klass).mount
    end

    def destroy
      # meta.children?&.each do |child|
      #   child.node.destroy
      # end
      #
      # ast.destroy
    end

    def emit(name, **args)
      if node = portal
        if event = node.event(name)
          meta.publisher.notify(event.value.name, **args)
        else
          raise Hokusai::Error.new("Invocation failed: @#{name} doesn't exist on #{node.type}")
        end
      end
    end

    def add_evented_styles(klass, event_name)
      return if portal.nil?

      portal.ast.style_list.each do |style_name|
        style = klass.styles_get[style_name]
        
        if style.nil?
          raise ArgumentError.new("Style (#{style_name}) doesn't exist in the styles for this block #{klass} - #{klass.styles_get.keys}")
        end

        if sattr = style[event_name]
          sattr.each do |key, value|
            meta.set_prop(key.to_sym, value)
          end
        end
      end
    end

    def add_styles(klass)
      return if portal.nil?

      portal.ast.style_list.each do |style_name|
        style = klass.styles_get[style_name]

        raise Hokusai::Error.new("Style #{style_name} doesn't exist in the styles for this block #{klass} - #{klass.styles_get.keys}") if style.nil?

        if sattr = style["default"]
          sattr.each do |key, value|
            meta.set_prop(key.to_sym, value)
          end
        end
      end
    end

    def add_props_from_block(parent, context: nil)
      if local_portal = portal
        if block = parent
          local_portal.ast.props.each do |_, prop|
            method = prop.value.method

            case prop.computed?
            when true
              if prop.value.args.size > 0 && context
                value = context.send_target(block, prop.value)
              elsif context&.table&.[](method)
                value = context.table[method]
              else
                value = block.instance_eval(method)
              end
            else
              value = method
            end

            meta.set_prop(prop.name.to_sym, value) unless value.nil?
          end
        end
      end
    end
  end
end