module Hokusai
  module Harness
    include Theorem::Control::Harness

    load_tests do |options|
      filtered_registry({})
    end
  end
    
  module Hypothesis
    include Harness
    include Theorem::Control::Hypothesis
    include Theorem::StdoutReporter
  end

  class Test
    include Hypothesis
    include Matchers
  end
end


def get_block_by_type(block, type)
  return block if (block.node.ast.type == type) || (block.node.portal&.ast&.has_if_condition? && block.node.portal&.ast&.type == type)

  block.children.each do |child|
    if b = get_block_by_type(child, type)
      return b
    end
  end

  nil
end

def get_blocks_by_type(block, type, results = [])
  if block.node.ast.type == type
    results << block

    return
  end

  block.children.each do |child|
    get_blocks_by_type(child, type, results)
  end

  results
end

require_relative "./ast"
require_relative "./diff"
require_relative "./directives"
require_relative "./providers"
require_relative "./publisher"
require_relative "./block"
require_relative "./slots"
require_relative "./util/piece_table"

Hokusai::Hypothesis.run!
