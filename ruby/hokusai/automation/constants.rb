require "logger"
require_relative "./keys_transcoder"

module Hokusai::Automation
  class Error < StandardError; end

  Log = Logger.new($stdout)

  case ENV["LOG_LEVEL"]
  when "debug"
    Log.level = Logger::DEBUG
  when "info"
    Log.level = Logger::INFO
  when "warn"
    Log.level = Logger::WARN
  when "error"
    Log.level = Logger::ERROR
  end

  CODE_TO_HML_KEY = {
    '\0' => :null,
    '\'' => :apostrophe,
    ',' => :comma,
    '-' => :minus,
    '.' => :period,
    '\\' => :slash,
    '0' => :zero,
    '1' => :one,
    '2' => :two,
    '3' => :three,
    "4" => :four,
    '5' => :five,
    '6' => :six,
    '7' => :seven,
    '8' => :eight,
    '9' => :nine,
    ';' => :semicolon,
    '=' => :equal,
    'A' => :a,
    'B' => :b,
    'C' => :c,
    'D' => :d,
    'E' => :e,
    'F' => :f,
    'G' => :g,
    'H' => :h,
    'I' => :i,
    'J' => :j,
    'K' => :k,
    'L' => :l,
    'M' => :m,
    'N' => :n,
    'O' => :o,
    'P' => :p,
    'Q' => :q,
    'R' => :r,
    'S' => :s,
    'T' => :t,
    'U' => :u,
    'V' => :v,
    'W' => :w,
    'X' => :x,
    'Y' => :y,
    'Z' => :z,
    'a' => :a,
    'b' => :b,
    'c' => :c,
    'd' => :d,
    'e' => :e,
    'f' => :f,
    'g' => :g,
    'h' => :h,
    'i' => :i,
    'j' => :j,
    'k' => :k,
    'l' => :l,
    'm' => :m,
    'n' => :n,
    'o' => :o,
    'p' => :p,
    'q' => :q,
    'r' => :r,
    's' => :s,
    't' => :t,
    'u' => :u,
    'v' => :v,
    'w' => :w,
    'x' => :x,
    'y' => :y,
    'z' => :z,
    '[' => :left_bracket,
    '/' => :backslash,
    ']' => :right_bracket,
    '~' => :grave,
    ' ' => :space,
    '\e' => :escape,
  }.merge(KeysTranscoder::KEYS.to_h { |k, v| [k, k]})
end