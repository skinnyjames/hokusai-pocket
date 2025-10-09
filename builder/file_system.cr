require "baked_file_system"
require "./resolver"

module Hokusai::Pocket
  class FileStorage
    macro embed_hokusai
      @@hokusai_code = {{ run("#{__DIR__}/resolve_hokusai.cr").stringify }}
    end

    embed_hokusai

    def self.hokusai_code
      @@hokusai_code
    end

    extend BakedFileSystem

    bake_folder "#{__DIR__}/../include"
    bake_folder "#{__DIR__}/../src"
    bake_folder "#{__DIR__}/../grammar/src"
  end
end