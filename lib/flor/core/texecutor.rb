
module Flor

  class TransientExecutor < Executor

    class TransientUnit

      attr_accessor :conf, :opts
      attr_reader :loader, :logger
      attr_reader :journal
      attr_accessor :archive

      def initialize(conf)

        @conf = conf
        @opts = {}
        @logger = TransientLogger.new(self)
        @journal = []
        @archive = nil
      end

      def notify(executor, msg)

        return [] if msg['consumed']

        @logger.notify(executor, msg)
        @journal << msg

        []
      end

      def archive_node(exid, node)

        (@archive[exid] ||= {})[node['nid']] = Flor.dup(node) if @archive
      end

      def has_tasker?(exid, tname)

        false
      end
    end

    class TransientLogger

      def initialize(unit)

        @unit = unit

        @out = Flor::Logger::Out.prepare(unit)
      end

      def notify(executor, message)

        return if message['point'] == 'end'
        return unless @unit.conf['log_msg']

        @out.puts(Flor.message_to_one_line_s(executor, message, out: @out))
      end

      def log_err(executor, message, opts={})

        return unless @unit.conf['log_err']

        @out.puts(
          Flor.msg_to_detail_s(executor, message, opts.merge(flag: true)))
      end

      def log_src(source, opts, log_opts={})

        return unless @unit.conf['log_src']

        @out.puts(Flor.src_to_s(source, opts, log_opts))
      end

      def log_tree(tree, nid='0', opts={})

        return unless @unit.conf['log_tree']

        @out.puts(Flor.tree_to_s(tree, nid, opts.merge(out: @out)))
      end
    end

    def initialize(conf={})

      conf = Flor::Conf.prepare(conf, {})

      super(
        TransientUnit.new(conf),
        [], # no hooks
        [], # no traps
        {
          'exid' => Flor.generate_exid('eval', 'u0'),
          'nodes' => {}, 'errors' => [], 'counters' => {},
          #'ashes' => {},
          'start' => Flor.tstamp
        })

      @unit.archive = {} if conf['archive']
    end

    def journal; @unit.journal; end
    def archive; @unit.archive[exid]; end

    def launch(tree, opts={})

      @unit.opts = opts
      @unit.archive ||= {} if opts[:archive]

      @unit.logger.log_src(tree, opts)

      messages = [ Flor.make_launch_msg(@execution['exid'], tree, opts) ]

      @unit.logger.log_tree(messages.first['tree'], '0', opts)

      walk(messages, opts)
    end

    def walk(messages, opts={})

      loop do

        message = messages.shift
        return nil unless message

        if message['point'] == 'terminated' && messages.any?
          #
          # try to handle 'terminated' last
          #
          messages << message
          message = messages.shift
        end

        msgs = process(message)

        messages.concat(msgs)

        return messages \
          if message_match?(message, opts[:until_after])
        return messages \
          if message_match?(messages, opts[:until])
            #
            # Walk is suspended if options :until_after or :until
            # are satisfied.
            # Returns the remaining messages.

        return message \
          if message['point'] == 'terminated'
        return message \
          if message['point'] == 'failed' && message['on_error'] == nil
            #
            # Walk exits when execution terminates or fails (without on_error).
            # Returns the last message
      end
    end

    def step(message)

      process(message)
    end

    # Used in specs when testing multiple message arrival order on
    # a "suite" of transient executors
    #
    def clone

      c = TransientExecutor.allocate

      c.instance_variable_set(:@unit, @unit)
      c.instance_variable_set(:@traps, []) # not useful for a TransientEx clone
      c.instance_variable_set(:@execution, Flor.dup(@execution))

      c
    end

    protected

    # TODO eventually merge with Waiter.parse_serie
    #
    def message_match?(msg_s, ountil)

      return false unless ountil

      ms = msg_s; ms = [ ms ] if ms.is_a?(Hash)

      nid, point = ountil.split(' ')

      ms.find { |m| m['nid'] == nid && m['point'] == point }
    end
  end

  class ConfExecutor < TransientExecutor

    def self.interpret(path)

      s =
        if path.match(/[\r\n]/)
          path.strip
        else
          ls = File.readlines(path)
          ls.reject! { |l| l.strip[0, 1] == '#' }
          s = ls.join("\n").strip
        end

      a, b = s[0, 1], s[-1, 1]

      s =
        if (a == '{' && b == '}') || (a == '[' && b == ']')
          s
        elsif s.match(/[^\r\n{]+:/) || s == ''
          "{\n#{s}\n}"
        else
          "[\n#{s}\n]"
        end

      vs = Hash.new { |h, k| k }
      class << vs
        def has_key?(k)
          prc = Flor::Procedure[k]
          ( ! prc) || ( ! prc.core?) # ignore non-core procedures
        end
      end

      vs['root'] = determine_root(path)

      vs['ruby_version'] = RUBY_VERSION
      vs['ruby_platform'] = RUBY_PLATFORM

      c = (ENV['FLOR_DEBUG'] || '').match(/conf/) ? false : true
      r = (self.new('conf' => c)).launch(s, vars: vs)

      unless r['point'] == 'terminated'
        ae = ArgumentError.new("Error while reading conf: #{r['error']['msg']}")
        ae.set_backtrace(r['error']['trc'])
        fail ae
      end

      o = Flor.dup(r['payload']['ret'])

      if o.is_a?(Hash)
        o['_path'] = path unless path.match(/[\r\n]/)
        o['root'] ||= Flor.relativize_path(vs['root'])
      elsif o.is_a?(Array)
        o.each { |e| e['_path'] = path } unless path.match(/[\r\n]/)
      end

      o
    end

    def self.determine_root(path)

      dir = File.absolute_path(File.dirname(path))
      ps = dir.split(File::SEPARATOR)

      ps.last == 'etc' ? File.absolute_path(File.join(dir, '..')) : dir
    end

    def self.interpret_line(s)

      r = interpret("\n#{s}")
      r.delete('root') if r.is_a?(Hash)

      r
    end
  end
end

