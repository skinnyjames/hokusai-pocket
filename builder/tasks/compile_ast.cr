@[Barista::BelongsTo(Hokusai::Pocket::Builder)]
class Hokusai::Pocket::Tasks::CompileAst < Barista::Task
  include_behavior Software
  include Hokusai::Pocket::Task
  include Mixins::BuildAst

  nametag "compile-ast"
end
