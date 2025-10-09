# module Hokusai
#   class Style
#     attr_reader :raw

#     def self.parse(template)
#       raw = LibHokusai.parse_style(template)
#       new(parse_styles(raw))
#     end

#     def self.parse_styles(raw)
#       styles = {}

#       until raw.null?
#         styles[raw[:name]] = parse_attributes(raw[:attributes])

#         raw = raw[:next]
#       end

#       styles
#     end

#     def self.parse_attributes(raw)
#       attributes = {}

#       until raw.null?
#         case raw[:type]
#         when :style_int
#           value = raw[:value].to_i
#         when :style_bool
#           value = (raw[:value] == "true")
#         when :style_float
#           value = raw[:value].to_f
#         when :style_string
#           value = raw[:value]
#         when :style_func
#           value = parse_function(raw[:function_name], raw[:value])
#         end

#         attributes[raw[:name]] = value
        
#         raw = raw[:next]
#       end

#       attributes
#     end

#     def self.parse_function(name, value)
#       case name
#       when "rgb"
#         Color.convert(value)
#       when "outline"
#         Outline.convert(value)
#       when "padding"
#         Padding.convert(value)
#       else
#         raise Hokusai::Error.new("Unknown style function #{name}")
#       end
#     end

#     def initialize(elements)
#       @elements = elements
#     end

#     def [](element_name)
#       @elements[element_name]
#     end

#     def keys
#       @elements.keys
#     end
#   end
# end