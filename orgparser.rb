# -*- coding: utf-8 -*-

class OrgParser

  HEADLINE_WITH_TAG_RE = /^(\*+)\s+(.+)\s+:(\S+):\s*$/
  HEADLINE_RE  = /^(\*+)\s+(.+)/
  UNORDERED_LIST_RE = /^\s*[-+*]\s/
  ORDERED_LIST_RE = /^\s*\d+[.)]\s/
  DEFLIST_RE = /^\s*-(.+)\s+::\s+(.+)/
  TABLE_RE = /^\s*\|(.+)\|\s*$/
  LINE_EXAMPLE_RE = /^\s*:\s+(.+)\s*$/
  SRC_NAME_RE = /^\s*#\+SRCNAME:\s+(\S+)/i
  BEGIN_SRC_RE = /^\s*#\+BEGIN_SRC\s+(\S+)/i
  END_SRC_RE = /^\s*#\+END_SRC/i
  BEGIN_COMMENT_RE = /^\s*#\+BEGIN_(\S+)/i
  END_COMMENT_STR = '^\s*#\+END_'
  COMMENT_RE = /^#/
  INDENT_COMMENT_RE = /^\s*#\+/
  URL_RE_STR = '(?:https?|ftp)(?::\/\/[-_.!~*\'()a-zA-Z0-9;\/?:\@&=+\$,%#]+)'
  DECORATION_RE_FORMAT = '\s%1$s(\S.*\S|\S)%1$s\s'
  SYMBOLS = {bold: '\*', italic: '/', underlined: '_', code: '=', verbatim: '~', strike: '\+'}
  FORMAT_METHOD_RE = /parse_.+_format/
  DECORATION_METHOD_RE = /parse_.+_decoration/


  def parse(src)
    buf = []

    lines = File.readlines(src).map { |line| line.chomp }
    lines = format_input_src(lines)
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
        lang = $1
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
          # 文字装飾を変換
          buf << decorate(lines.shift)
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

    buf = format_output_src(buf)
    buf.join("\n")
  end


  private

  # 警告は各メソッドにつき一回表示するため，
  # 呼び出し元のメソッドは空のメソッドにオーバーライドされる．
  def print_undefined_warning
    if /^(.+?):(\d+)(?::in `(.*)')?/ =~ caller.first
      $stderr.puts "Warning: Called undefined method \"#{$3}\""
      self.class.instance_eval { define_method($3){|arg| []} }
    end
    []
  end

  # FORMAT_METHOD_RE, DECORATION_METHOD_RE に一致するメソッドを呼び出したときは
  # 警告を出力して引数を整形せずにそのまま返す
  def method_missing(action, *args)
    if action =~ FORMAT_METHOD_RE or action =~ DECORATION_METHOD_RE
      $stderr.puts "Warning: Called undefined method \"#{action}\""
      self.class.instance_eval { define_method(action){|a| a} }
      args[0]
    else
      super
    end
  end


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


  def decorate(line)
    SYMBOLS.each do |decoration, symbol|
      line.gsub!(/#{sprintf(DECORATION_RE_FORMAT, symbol)}/) do |match, string|
        decoration_method = "parse_#{decoration.to_s.downcase}_decoration".to_sym
        " #{send(decoration_method, $1)} "
      end
    end
    line
  end


  ##################################################
  # 以下，オーバーライド推奨メソッド
  #
  # -- 別途コメントがないメソッドの引数・返り値 --
  # 引数
  #   lines: 各行を split した文字列リスト
  # 返り値
  #   文字列のリスト
  ##################################################

  # parse する前に入力テキストに整形を行う
  def format_input_src(lines)
    lines
  end

  # 出力するバッファに最後の整形を行う
  def format_output_src(lines)
    lines
  end

  # level: トップから数えた見出しの深さ
  # title: 見出しの文字列tags はタグの各要素
  # tags:  各タグを要素とした文字列配列
  # 返り値: タイトルの行にしたい文字列
  def parse_headline(level, title, *tags)
    print_undefined_warning
  end

  def parse_unordered_list(lines)
    print_undefined_warning
  end

  def parse_ordered_list(lines)
    print_undefined_warning
  end

  def parse_deflist(lines)
    print_undefined_warning
  end

  # table: Array[row][column] の二次元配列
  def parse_table(table)
    print_undefined_warning
  end

  def parse_line_example(lines)
    print_undefined_warning
  end

  # lang: ソースコードの言語
  # name: ソースファイル名
  def parse_src_format(lines, lang, name)
    print_undefined_warning
  end

  # link: URL
  # title: ページのタイトル
  # 返り値: タイトル付きリンクの置換後の文字列
  def replaced_link_str(link, title)
    print_undefined_warning
  end

  # その他，子クラスで定義できるメソッド
  #
  # [parse_xxx_format]
  #   #+BEGIN_XXX を整形するメソッド
  # 例:
  #   def parse_example_format(lines); end
  #   def parse_quote_format(lines); end
  #
  # [parse_xxx_decoration]
  #   文字装飾を生計するメソッドで
  #   xxx は SYMBOLS の各キーが入る
  # 引数:
  #   装飾する文字列(装飾記号は削除済み)
  # 例:
  #   def parse_bold_decoration(str); end

end
