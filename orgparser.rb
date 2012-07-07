# -*- coding: utf-8 -*-

class OrgParser

  HEADLINE_WITH_TAG_RE = /^(\*+)\s+(.+)\s+:(\S+):\s*$/
  HEADLINE_RE  = /^(\*+)\s+(.+)/
  UNORDERED_LIST_RE = /^\s*[-+*]\s/
  ORDERED_LIST_RE = /^\s*\d+[.)]\s/
  DEFLIST_RE = /^\s*-(.+)\s+::\s+(.+)/
  TABLE_RE = /^\s*\|(.+)\|\s*$/
  LINE_EXAMPLE_RE = /^\s*:\s+(.+)\s*$/
  SRC_NAME_RE = /^\s*#\+srcname:\s+(\S+)/i
  BEGIN_SRC_RE = /^\s*#\+begin_(src)\s+(\S+)/i
  END_SRC_RE = /^\s*#\+end_src/i
  BEGIN_COMMENT_RE = /^\s*#\+BEGIN_(\S+)/i
  END_COMMENT_STR = '^\s*#\+END_'
  COMMENT_RE = /^#/
  INDENT_COMMENT_RE = /^\s*#\+/
  URL_RE_STR = '(?:https?|ftp)(?::\/\/[-_.!~*\'()a-zA-Z0-9;\/?:\@&=+\$,%#]+)'


  def parse(src)
    buf = []

    lines = File.readlines(format_input_src(src)).map { |line| line.chomp }
    srcname = nil

    # Org Mode 文書を別の書式に変換して，文字列で返す．
    while lines.first
      case lines.first
      when HEADLINE_WITH_TAG_RE
        lines.shift
        buf.concat [parse_headline($1.length, $2, $3.split(':'))]
      when HEADLINE_RE
        lines.shift
        buf.concat [parse_headline($1.length, $2)]
      when UNORDERED_LIST_RE
        buf.concat parse_unordered_list(take_block(lines, UNORDERED_LIST_RE))
      when ORDERED_LIST_RE
        buf.concat parse_ordered_list(take_block(lines, ORDERED_LIST_RE))
      when DEFLIST_RE
        buf.concat parse_deflist(take_block(lines, DEFLIST_RE))
      when TABLE_RE
        block = take_block(lines, TABLE_RE)
        block.map do |line|
          line =~ TABLE_RE
          $1.split('|')
        end
        buf.concat parse_table(block)
      when LINE_EXAMPLE_RE
        block = take_block(lines, LINE_EXAMPLE_RE)
        block.map do |line|
          line =~ LINE_EXAMPLE_RE
          $1
        end
        buf.concat parse_line_example(block)
      when SRC_NAME_RE
        lines.shift
        srcname = $1
        next
      when BEGIN_SRC_RE
        format, lang = $1, $2
        src = take_format(lines, END_SRC_RE)
        buf.concat parse_src_format(src[1..-2], lang, srcname)
      when BEGIN_COMMENT_RE
        format = $1
        parse_method = "parse_#{format.downcase}_format".to_sym
        src = take_format(lines, /#{END_COMMENT_STR}#{format}/i)
        parsed = send(parse_method, src[1..-2])
        buf.concat parsed
      else
        if lines.first =~ COMMENT_RE or lines.first =~ INDENT_COMMENT_RE
          # コメント行は除去
          lines.shift
        else
          buf << lines.shift
        end
      end
      srcname = nil
    end

    # リンクの置換
    buf.map! do |line|
      line.gsub(/\[\[(#{URL_RE_STR})\]\[([^\[\]]+)\]?\]/) do
        link, title = $1, $2
        replaced_link_str(link, title)
      end
    end

    format_output_src(buf)
    buf.join("\n")
  end


  private

  # lines の先頭から正規表現 marker にマッチする行を全て取り出して配列で返す．
  # このとき，lines から marker にマッチした行は取り除かれる．marker は取り除かない．
  def take_block(lines, marker)
    buf = []
    until lines.empty?
      break unless marker =~ lines.first
      buf.push lines.shift
    end
    buf
  end

  # lines の先頭から正規表現 end_marker にマッチするまでの行を全て取り出して配列で返す．
  # このとき，lines から marker にマッチした行は取り除かれる．marker は取り除かない．
  def take_format(lines, end_marker)
    buf = []
    finished = false
    until lines.empty? or finished
      finished = true if end_marker =~ lines.first
      buf.push lines.shift
    end
    buf
  end

  # 警告は各メソッドにつき一回表示するため，
  # 呼び出し元のメソッドは空のメソッドにオーバーライドされる．
  def print_undefined_warning
    if /^(.+?):(\d+)(?::in `(.*)')?/ =~ caller.first
      $stderr.puts "Warning: Called undefined method \"#{$3}\""
      self.class.instance_eval { define_method($3){|arg| []} }
    end
    []
  end


  ####################################
  # 以下，オーバーライド推奨メソッド
  ####################################

  def format_input_src(src)
    src
  end

  def format_output_src(src)
    src
  end

  # tags は各要素に分割された配列．
  def parse_headline(title, tags = [])
    print_undefined_warning
  end

  # 引数 list は行ごとの配列で，整形はされていない
  def parse_unordered_list(list)
    print_undefined_warning
  end

  def parse_ordered_list(list)
    print_undefined_warning
  end

  def parse_deflist(list)
    print_undefined_warning
  end

  # 引数 table は Array[row][column] の二次元配列
  def parse_table(table)
    print_undefined_warning
  end

  def parse_line_example(lines)
    print_undefined_warning
  end

  def parse_src_format(src, lang, name)
    print_undefined_warning
  end

  # タイトル付きリンクの置換後の文字列
  def replaced_link_str(link, title)
    print_undefined_warning
  end

end
