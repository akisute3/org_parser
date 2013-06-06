#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
$LOAD_PATH.unshift File.dirname(__FILE__)
require 'orgparser'

# Org Mode 文書を Qiita の書式に変換する
class OrgToQiita < OrgParser
  private

  def parse_headline(level, title, *tags)
    "#{"#" * level} #{title}"
  end

  def parse_unordered_list(lines)
    lines
  end

  def parse_ordered_list(lines)
    lines.map {|line| line.sub(/(\d+)[.)]/, '\1.')}
  end

  def parse_src_format(lines, lang, name)
    if name
      lines.unshift("```#{lang}:#{name}").push("```")
    else
      lines.unshift("```#{lang}").push("```")
    end
  end

  def parse_quote_format(lines)
    lines.map {|line| "> #{line}"}
  end

  def replaced_link_str(link, title)
    title ? "[#{title}](#{link})" : link
  end

  def parse_example_format(lines)
    lines.unshift("```").push("```")
  end

  def parse_bold_decoration(str)
    "**#{str}**"
  end

  def parse_italic_decoration(str)
    "*#{str}*"
  end

  def parse_code_decoration(str)
    "`#{str}`"
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
