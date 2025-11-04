MRuby::Gem::Specification.new('mruby-hokusai-pocket') do |spec|
  spec.license = 'MIT'
  spec.author  = 'skinnyjames'
  spec.summary = 'gem for making portable guis'
  spec.version = '0.1.0'

  if spec.respond_to? :search_package
    search_package 'tree-sitter'
    search_package 'raylib'
  end

  spec.cc.include_paths << "#{__dir__}/grammar/src"
  spec.objs += [
    "#{__dir__}/grammar/src/parser.c",
    "#{__dir__}/grammar/src/scanner.c"
  ].map{ |f| f.relative_path_from(dir).pathmap("#{build_dir}/%X#{spec.exts.object}" ) }

  spec.add_dependency "mruby-regexp-pcre"
  # spec.add_dependency "mruby-compar-ext"
  # spec.add_dependency "mruby-enum-ext"
  # spec.add_dependency "mruby-string-ext"
  # spec.add_dependency "mruby-numeric-ext"
  # spec.add_dependency "mruby-array-ext"
  # spec.add_dependency "mruby-hash-ext"
  # spec.add_dependency "mruby-range-ext"
  # spec.add_dependency "mruby-proc-ext"
  # spec.add_dependency "mruby-symbol-ext"
  # spec.add_dependency "mruby-object-ext"
  # spec.add_dependency "mruby-objectspace"
  # spec.add_dependency "mruby-set"
  # spec.add_dependency "mruby-fiber"
  # spec.add_dependency "mruby-enumerator"
  # spec.add_dependency "mruby-enum-lazy"
  # spec.add_dependency "mruby-enum-chain"
  # spec.add_dependency "mruby-toplevel-ext"
  # spec.add_dependency "mruby-kernel-ext"
  # spec.add_dependency "mruby-class-ext"
  # spec.add_dependency "mruby-catch"

  if ENV["TEST"]
    spec.add_dependency 'mruby-bin-theorem'
  end
end