
module Flor

  class Dollar

    module Parser include Raabro

#static fabr_tree *_str(fabr_input *i)
#{
#  return fabr_rex("s", i,
#    "("
#      "\\\\\\)" "|"
#      "[^\\$\\)]" "|"
#      "\\$[^\\(]"
#    ")+");
#}
      def istr(i)
        rex(:str, i, %r{
          ( \\\) | [^\$)] | \$[^(] )+
        }x)
      end

#static fabr_tree *_outerstr(fabr_input *i)
#{
#  return fabr_rex("s", i,
#    "("
#      "[^\\$]" "|" // doesn't mind ")"
#      "\\$[^\\(]"
#    ")+");
#}
      def ostr(i)
        rex(:str, i, %r{
          ( [^\$] | \$(?!\() )+
        }x)
      end
        #
        # ( [^\$] | \$(?!\() )+
        # one or more of (not a dollar or a dollar followed by sthing else
        # than a parenthesis opening)

      def pe(i); str(nil, i, ')'); end
      def dois(i); alt(nil, i, :dollar, :istr); end
      def span(i); rep(:span, i, :dois, 0); end
      def dps(i); str(nil, i, '$('); end
      def dollar(i); seq(:dollar, i, :dps, :span, :pe); end
      def doos(i); alt(nil, i, :dollar, :ostr); end
      def outer(i); rep(:span, i, :doos, 0); end

      def rewrite_str(t)
        t.string
      end
      def rewrite_dollar(t)
        cn = rewrite(t.children[1])
        c = cn.first
        if cn.size == 1 && c.is_a?(String)
          [ :dol, c ]
        else
          [ :dol, cn ]
        end
      end
      def rewrite_span(t)
        t.children.collect { |c| rewrite(c) }
      end
    end # module Parser

    module PipeParser include Raabro

      def elt(i); rex(:elt, i, /[^|]+/); end
      def pipe(i); rex(:pipe, i, /\|\|?/); end
      def elts(i); jseq(:elts, i, :elt, :pipe); end

      def rewrite_elt(t); t.string; end
      def rewrite_pipe(t); t.string == '|' ? :pipe : :dpipe; end
      def rewrite_elts(t); t.children.collect { |e| rewrite(e) }; end
    end # module PipeParser

    #def lookup(s)
    #  # ...
    #end
      #
      # the signature

    # Called when joining multiple results in a string. Easily overwritable.
    #
    def stringify(v)

      case v
      when Array, Hash then JSON.dump(v)
      else v.to_s
      end
    end

    def quote(s, force)

      return s if force == false && s[0, 1] == '"' && s[-1, 1] == '"'

      JSON.dump([ s ])[1..-2]
    end

    def match(rex, s)

      s.match(rex) ? s : false
    end

    def substitute(pat, rpl, gix, s)

      ops =
        (gix.index('i') ? Regexp::IGNORECASE : 0) |
        (gix.index('x') ? Regexp::EXTENDED : 0)

      rex = Regexp.new(pat, ops)

      gix.index('g') ? s.gsub(rex, rpl) : s.sub(rex, rpl)
    end

    def lfilter(s, cmp, len)

      l = s.length

      case cmp
      when '>' then l > len
      when '>=' then l >= len
      when '<' then l < len
      when '<=' then l <= len
      when '=', '==' then l == len
      when '!=', '<>' then l != len
      else false
      end
    end

    def to_json(o)

      case o
      when Array, Hash then JSON.dump(o)
      else JSON.dump([ o ])[1..-2]
      end
    end

    def call(fun, o)

      # NB: yes, $1..$9 are thread-safe (and local, not global)

      case fun

      when 'u' then o.to_s.upcase
      when 'd' then o.to_s.downcase
      when 'r' then o.reverse
      when 'c' then o.to_s.capitalize.gsub(/\s[a-z]/) { |c| c.upcase }
      when 'q' then quote(o, false)
      when 'Q' then quote(o, true)
      when 'l' then o.length.to_s

      when 'json' then to_json(o)

      when /^j(.+)/
        o.respond_to?(:join) ? o.join($1) : o

      when /\Am\/(.+)\/\z/
        match($1, o.to_s)
      when /\As\/(.*[^\\]\/)(.+)\/([gix]*)\z/
        substitute($1.chop, $2, $3, o.to_s)

      when /\A-?\d+\z/ then o.to_s[fun.to_i]
      when /\A(-?\d+), *(-?\d+)\z/ then o.to_s[$1.to_i, $2.to_i]
      when /\A(-?\d+)\.\.(-?\d+)\z/ then o.to_s[$1.to_i..$2.to_i]

      when /\A\s*l\s*([><=!]=?|<>)\s*(\d+)\z/
        lfilter(o.to_s, $1, $2.to_i) ? o.to_s : nil

      else o
      end
    end

    def unescape(s)

      s.gsub(/\\[\$)]/) { |m| m[1, 1] }
    end

    def do_eval(t)

      #return t if t.is_a?(String)
      return unescape(t) if t.is_a?(String)

      return t.collect { |c| stringify(do_eval(c)) }.join if t[0] != :dol

      k = do_eval(t[1])
      ks = PipeParser.parse(k)

      result = nil
      mode = :lookup # vs :call

      ks.each do |k|

        if k == :pipe then mode = :call; next; end
        if k == :dpipe && result then break; end
        if k == :dpipe then mode = :lookup; next; end

        result =
          if mode == :lookup
            k[0, 1] == "'" ? k[1..-1] : lookup(k)
          else # :call
            call(k, result)
          end
      end

      result
    end

    def expand(s)

      return s unless s.index('$')

      #Raabro.pp(Parser.parse(s, debug: 2))
      t = Parser.parse(s)

      return s unless t

      t = t.first if t.size == 1

      do_eval(t)
    end
  end
end

