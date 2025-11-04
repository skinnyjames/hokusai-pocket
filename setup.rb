#!/usr/bin/env ruby

# thanks: https://github.com/iij/mruby-dir/blob/master/run_test.rb
gemname = File.basename(File.dirname(File.expand_path __FILE__))

if __FILE__ == $0
  repository, dir = 'https://github.com/mruby/mruby.git', 'tmp/mruby'
  build_args = ARGV
  build_args = ['all']  if build_args.nil? or build_args.empty?
  build_args.unshift("clean") if ENV["CLEAN"]

  Dir.mkdir 'tmp' unless File.exist?('tmp')
  unless File.exist?(dir)
    system "git clone #{repository} #{dir}"
  end

  system(%Q[ruby resolve.rb && cd #{dir}; MRUBY_CONFIG=#{__dir__}/build_config.rb rake #{build_args.join(' ')}])
  # exit system(%Q[cd #{__dir__}; #{dir}/bin/theorize test])
end
