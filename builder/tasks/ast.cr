@[Barista::BelongsTo(Hokusai::Pocket::Builder)]
class Hokusai::Pocket::Tasks::Ast < Barista::Task
  include_behavior Software
  include Hokusai::Pocket::Task
  include Mixins::BuildAst

  nametag "ast"

  dependency Raylib
  dependency TreeSitter
  dependency MRuby
end
