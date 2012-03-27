# encoding: utf-8

if defined?(Encoding) then
  Encoding.default_external = 'utf-8'
  Encoding.default_internal = 'utf-8'
else
  $KCODE = 'utf-8'
end
ENV["LANG"] = 'en_US.UTF-8'

begin
  # Compatibility stuff
  RUBY_ENGINE = "unknown" unless defined? RUBY_ENGINE
  unless IRB.conf[:AT_EXIT]
    IRB.conf[:AT_EXIT] = []
    Kernel.at_exit do
      IRB.conf[:AT_EXIT].each do |hook|
        hook.call
      end
    end
  end

  ## Some stuff I commonly use
  # Ok, I usually hate that and prefer plain requires, but due to begin/rescue for each of it, I'll do it this way
  %w[
    pp
    awesome_print
    yaml
    enumerator
    readline
  ].each do |path|
    begin
      require path
    rescue LoadError
      warn "Failed to load #{path.inspect} in #{__FILE__}:#{__LINE__-2}" if $VERBOSE
    end
  end



  module IRBUtilities; module_function
    MethodMethod          = Object.instance_method(:method)
    MethodInstanceMethod  = Module.instance_method(:instance_method)
    MethodIsA             = Object.instance_method(:is_a?)
    MethodIsDescendant    = Module.instance_method(:<)

    def self._method(obj, *args, &block)
      MethodMethod.bind(obj).call(*args, &block)
    end

    def self._instance_method(obj, *args, &block)
      MethodInstanceMethod.bind(obj).call(*args, &block)
    end

    def self._is_a?(obj, klass)
      MethodIsA.bind(obj).call(klass)
    end

    def self._is_descendant?(obj, klass)
      MethodIsDescendant.bind(obj).call(klass)
    end

    def pretty_print_methods(obj, meths)
      descs = meths.map { |n, m|
        i = 0
        params = m.parameters.map { |type, name|
          case type
            when :req then name || "arg#{i+=1}"
            when :opt then "#{name || "arg#{i+=1}"}=?"
            when :rest then "*#{name || "rest"}"
            when :block then "&#{name || "block"}"
            else "??"
          end
        }
        ["  #{n}(#{params.join(", ")})", m.source_location ? m.source_location.join(':') : '[native]']
      }
      width = descs.map { |a,b| a.size }.max
      descs.each do |a,b|
        $stdout.printf "%-*s %s\n", width, a, b
      end

      descs.size
    end
  end



  ## Load history
  module IRBHistory
    @history_file           = File.expand_path('~/.irb_session_history')
    @max_sessions           = 20
    @max_lines_per_session  = 1000
    @max_lines              = 10000
    @sessions               = {}
    @history                = []
    @current_history        = nil

    @current_wd             = File.expand_path('.')
    @current_ruby           = "#{RUBY_ENGINE}-#{RUBY_VERSION}".gsub(/\s+/, '_')
    @current_ppid           = Process.ppid
    @current_key            = [@current_ppid, @current_wd, @current_ruby]

    class <<self
      attr_reader :sessions, :history_file, :history, :current_history
      attr_reader :max_sessions, :max_lines_per_session, :max_lines
      attr_reader :current_wd, :current_ruby, :current_ppid, :current_key
    end

    def self.push(line)
      @current_history.push([Time.now.to_i, line])
      @current_history.shift if @current_history.length > @max_lines
    end

    def self.restore
      read_history_log
      restore_history
      restore_readline_history
    end

    def self.read_history_log
      sessions          = {}
      lost              = []

      current           = lost
      if File.exist?(@history_file) then
        File.foreach(@history_file).each_with_index do |line, line_no|
          if /^\# session time=(\d+), ppid=(\d+), ruby=(\S+), cwd=(.*)$/ =~ line then
            time, ppid, ruby, cwd = $1, $2, $3, $4
            current.replace(current.first(@max_lines_per_session)) # truncate array
            time        = time.to_i
            ppid        = ppid.to_i
            current     = []
            session_key = [ppid, cwd, ruby]
            sessions[session_key] = [time, current]
          elsif /^(\d+) (.*)$/ =~ line then
            time, code = $1, $2
            current << [time.to_i, code]
          else
            warn "Malformed line #{line_no+1}: #{line.inspect}"
          end
        end
        warn "#{lost.size} log lines without session" unless lost.empty?
        current.replace(current.first(@max_lines_per_session)) # truncate array
      end

      sessions[@current_key] ||= [Time.now.to_i, []]
      sorted            = sessions.sort_by { |key, (time, lines)| time }
      @sessions         = Hash[sorted.last(@max_sessions)]
      @current_history  = @sessions[@current_key] ? @sessions[@current_key].last : []
      nil
    end

    def self.restore_history
      @history  = []
      @sessions.sort_by { |(ppid, cwd, ruby), (time, lines)|
        [
          ppid == @current_ppid ? 1 : 0,    # matching ppid later (latest means first in history)
          cwd  == @current_wd ? 1 : 0,      # matching working directory later
          time                              # newer ones later
        ]
#      }.select { |(ppid, cwd, ruby), (time, lines)|
#        ruby == @current_ruby
      }.each do |(ppid, cwd, ruby), (time, lines)|
        @history.concat(lines)
      end
      @history.replace(@history.first(@max_lines)) # truncate
    end

    def self.restore_readline_history
      Readline::HISTORY.clear
      Readline::HISTORY.push(*@history.map(&:last))
    end

    def self.save
      return unless @current_history
      save_history = @current_history.first(@max_lines_per_session)
      @sessions.replace({@current_key => [Time.now.to_i, save_history]}.merge(@sessions))
      File.open(@history_file, 'a+:binary') do |fh|
        fh.flock(File::LOCK_EX)
        fh.truncate(0)
        @sessions.each do |(ppid, cwd, ruby), (time, lines)|
          fh.puts "\# session time=#{time}, ppid=#{ppid}, ruby=#{ruby}, cwd=#{cwd}"
          lines.each do |line_time, line|
            fh.puts("#{line_time} #{line}")
          end
        end
      end
    end

    # utility function
    def self.sort_hash_by!(hash, &block)
      hash.replace(Hash[hash.sort_by(&block)])
    end
  end

  if defined? Readline then
    # Compat
    unless Readline::HISTORY.respond_to? :clear
      hist = Readline::HISTORY
      def hist.clear
        length.times do pop end
      end
    end
    IRBHistory.restore
    IRB.conf[:AT_EXIT] << proc { IRBHistory.save }

    module IRB
      begin
        require "readline"
        ::NBSP = "\302\240"
        require 'irb/completion'
        class ReadlineInputMethod < InputMethod
          def gets
            if l = readline(@prompt, false)
              l.gsub!(/\302\240/, "") # this line does the trick - it's for poor swiss people who have {|} on opt-<key> combo, which means that pressing opt too early or releasing it too late you generate a non-breaking space (opt-space) which causes a syntax error
              HISTORY.push(l) unless l.empty?
              IRBHistory.push(l)
              @line[@line_no += 1] = "#{l}\n"
            else
              @eof = true
              l
            end
          end
        end
        Readline.completion_append_character = ""
      rescue LoadError
      end
    end
  end



  ## A couple of core patches to make life in IRB a little bit nicer
  alias q exit

  module OriginalInspect
    def irb_inspect
      inspect
    end

    def self.wrap(klass)
      klass.class_eval do
        alias original_inspect inspect

        def inspect
          r = original_inspect
          r.extend OriginalInspect
          r
        end
      end
    end
  end
  class Object
    def eigenclass
      class<<self;self;end
    end
    def eigendef(*a,&b)
      eigenclass.send(:define_method, *a, &b)
    end
    def __m
      (methods-Object.methods).sort
    end
    if Method.method_defined? :parameters then
      def __mx
        meths  = methods-Object.methods
        meths -= Enumerable.instance_methods if IRBUtilities._is_a?(self, Enumerable)
        IRBUtilities.pretty_print_methods(self, meths.sort.map { |m| [m, IRBUtilities._method(self, m)] })
      end
    else
      def __mx
        warn "__mx requires Method#parameters"
        __m
      end
    end
    def i
      $stdout.puts inspect
      self
    end
    def ii
      $stdout.puts pretty_inspect
      self
    end
    def irb_inspect
      original = inspect
      if original.length > 100 then
        $stdout.sprintf "#<%p %s>", self.class, instance_variables.join(" ")
      else
        original
      end
    rescue
      "<<could not inspect object>>"
    end
  end
  class Module
    def __im
      (instance_methods-Object.instance_methods).sort
    end
    if Method.method_defined? :parameters then
      def __imx
        meths  = instance_methods-Object.methods
        meths -= Enumerable.instance_methods if IRBUtilities._is_descendant?(self, Enumerable)
        IRBUtilities.pretty_print_methods(self, meths.sort.map { |m| [m, IRBUtilities._instance_method(self, m)] })
      end
    else
      def __imx
        warn "__imx requires Method#parameters"
        __im
      end
    end
  end
  class String
    # Convenience method, see Regexp#show_match
    def show_match(regex)
      regex.show_match(self)
    end

    OriginalInspect.wrap(self)
#     def irb_inspect
#       if length <= 100 then
#         original_inspect
#       else
#         sub(/\A(.{89}).*(.{10})/m, '\1…\2').original_inspect
#       end
#     end
  end
  class Array
    OriginalInspect.wrap(self)
    def irb_inspect
      if size <= 100 then
        "[#{map(&:irb_inspect).join(', ')}]"
      else
        "[#{first(89).map(&:irb_inspect).join(', ')}, …, #{last(10).map(&:irb_inspect).join(', ')}]"
      end
    end
  end
  class Hash
    OriginalInspect.wrap(self)
    def irb_inspect
      if size <= 100 then
        "{#{map{|k,v| "#{k.irb_inspect} => #{v.irb_inspect}"}.join(', ')}}"
      else
        ary = to_a
        "{#{ary.first(89).map{|k,v| "#{k.irb_inspect} => #{v.irb_inspect}"}.join(', ')}, …, " \
        "#{ary.last(10).map{|k,v| "#{k.irb_inspect} => #{v.irb_inspect}"}.join(', ')}}"
      end
    end
  end
  module Enumerable
    def __m
      (methods-Object.methods-Enumerable.instance_methods).sort
    end
  end
  module Kernel
  module_function
    # Prints memory and cpu footprint of the server (uses ps in a subshell,
    # portability is therefore limited)
    def print_resource_usage
      ps_out = `ps -o vsz,rss,%cpu,%mem -p #{$$}`
      vsz, rss, cpu, pmem = ps_out.scan(/\d+(?:[.,]\d+)?/).map { |e| e.gsub(/,/,'.').to_f } # ps on 10.5.1 outputs ',' instead of '.' for MEM%
      virtual, real = (vsz-rss).div(1024), rss.div(1024)
      $stdout.printf "%dMB real, %dMB virtual, %.1f%% CPU, %.1f%% MEM\n", real, virtual, cpu, pmem
    end

    # Terminate the current process - the hard way
    def t!
      `kill -9 #{$$}`
    end

    # write data to a file
    def putf(content, path='~/Desktop/irb_dump.txt')
      File.open(File.expand_path(path), 'w') { |fh| fh.write(content) }
    end

    # tiny bench method
    def bench(n=100, runs=10)
      n = n.to_i
      t = []
      runs.times do
        a = Time.now
        for i in 1..n
          yield
        end
        t << (Time.now-a)*1000/n
      end
      mean   = t.inject { |a,b| a+b }.quo(t.size)
      stddev = t.map { |a| (a-mean)**2 }.inject { |a,b| a+b }.quo(t.size)**0.5
      [mean, stddev]
    end

    # tiny bench method with nice printing
    def pbench(n=1, runs=5, &b)
      m, s = *bench(n,runs,&b)
      p    = (100.0*s)/m
      $stdout.printf "ø %fms (%.1f%%)\n", m, p
    end

    # tiny bench method with nice printing,
    # runs multiple tests
    def mbench(n, runs, benches)
      label_width = benches.keys.max_by(&:length).length+1
      measures    = []
      benches.each do |label, b|
        m, s     = *bench(n,runs,&b)
        p        = (100.0*s)/m
        measures << [label, m]
        $stdout.printf "%-*s ø %fms (%.1f%%)\n", label_width, "#{label}:", m, p
      end

      measures.sort_by! { |l,m| m }
      rel = measures.first.last
      $stdout.puts measures.map { |l,m| sprintf "%s: %.1f", l, m/rel }.join(', ')
      nil
    end

    module PasswordString
      def inspect; "[PASSWORD]"; end
      def to_s; "[PASSWORD]"; end
      def dup; obj=super;obj.extend PasswordString; obj; end
      def clone; obj=super;obj.extend PasswordString; obj; end
    end

    def password
      `stty -echo`
      r = gets.chomp
      r.extend PasswordString
      r
    ensure
      `stty echo`
    end
    alias secret password

    # 1.9's p/pp return the arguments -> sucks in irb. let it return nil again.
    def p(*args)
      puts(args.map{|a|a.inspect})
      nil
    end
    def pp(*args)
      PP.pp(*args)
      nil
    end

    # Invoke an original method on an object that possibly overrides, fakes or removes it
    # Example:
    #   cm some_obj, :inspect, Object
    #   Object.instance_method(:inspect).bind(some_obj).call # is what that does
    def cm(obj, meth, klass=Object)
      klass.instance_method(meth).bind(obj).call
    end
  end

  class Regexp
    # Convenience method on Regexp so you can do
    # /an/.show_match("banana") # => "b<<an>>ana"
    def show_match(str)
      self =~ str

      "#{$`}<<#{$&}>>#{$'}"
    end
  end


  # Support methods for beedit
  require 'shellwords'
  module ::BBedit
    def self.open(obj)
      case obj
        when ::String
          `bbedit #{obj.shellescape}`
        when ::Method, ::UnboundMethod
          file, line = obj.source_location
          if file && File.readable?(file) then
            `bbedit #{file.shellescape}:#{line}`
          else
            "Can't open native method"
          end
      end
    end
  end
  class ::Method
    def bbedit
      BBedit.open(self)
    end
  end
  class ::UnboundMethod
    def bbedit
      BBedit.open(self)
    end
  end
  class ::Object
    def bbedit(name)
      method(name).bbedit
    end
  end



  ## Configure IRB
  ruby                    = ENV["rvm_ruby_string"] || "#{RUBY_ENGINE}-#{RUBY_VERSION}"
  prompt                  = {
    :PROMPT_I     => "\e[42m \e[0m #{ruby}:%03n:%i>> ",  # default prompt
    :PROMPT_S     => "\e[42m \e[0m #{ruby}:%03n:%i%l> ", # known continuation
    :PROMPT_C     => "\e[42m \e[0m #{ruby}:%03n:%i>> ",
    :PROMPT_N     => "\e[42m \e[0m #{ruby}:%03n:%i*> ",  # unknown continuation
    :RETURN       => "\e[42m \e[0m # => %s\n",
  }
  #IRB.conf[:INSPECT_MODE]     = "{ |obj| obj.irb_inspect }" # use that code to generate the reply-line
  IRB.conf.delete(:AUTO_INDENT) # irb checks for presence, not content... stupid
  IRB.conf[:PROMPT][:APEIROS] = prompt
  IRB.conf[:PROMPT_MODE]      = :APEIROS
rescue => e
  $stdout.puts e, *e.backtrace.first(5)
end
