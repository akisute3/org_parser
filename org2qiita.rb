#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
$LOAD_PATH.unshift File.dirname(__FILE__)
require 'orgparser'

# Org Mode 文書を Qiita の書式に変換する
class OrgToQiita < OrgParser
  private

  def format_input_src(src)
    src
  end

  def format_output_src(src)
    src
  end

  def parse_headline(level, title, tags = [])
    "#{"#" * level} #{title}"
  end

  def parse_unordered_list(list)
    list
  end

  def parse_ordered_list(list)
    list.map {|line| line.sub(/(\d+)[.)]/, '\1.')}
  end

  def parse_src_format(src, lang, name)
    if name
      src.unshift("```#{lang}:#{name}").push("```")
    else
      src.unshift("```#{lang}").push("```")
    end
  end

  def parse_quote_format(src)
    src.map {|line| "> #{line}"}
  end

  def replaced_link_str(link, title)
    title ? "[#{title}](#{link})" : link
  end
end


# 実行時の処理
if __FILE__ == $0
  oth = OrgToQiita.new
  while argv = ARGV.shift
    s = oth.parse(argv)
    output = argv.sub('.org', '.txt')
    open(output, "w") { |f|
      f.print s
    }
  end
end
