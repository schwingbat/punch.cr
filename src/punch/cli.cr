module CLI
  class Argument
    property name : String = ""
    property required : Bool = true
    property multiple : Bool = false
    property splat : Bool = false
  end

  class Signature
    @arguments = [] of Argument
    property string : String
    getter command : String

    @i : Int32 = 0
    @end : Int32 = 0
    @buffer : String = ""
    @in_arg : Bool = false
    @in_opt : Bool = false
    @in_splat : Bool = false
    @in_multi : Bool = false

    def initialize(@string)
      @command = @string.split(" ").first
      parse_args
    end

    def map_args(args)
      mapped_args = Hash(String, String | Array(String)).new

      @arguments.each_with_index do |argument, i|
        if args[i]?
          if argument.splat
            mapped_args[argument.name] = args[i...args.size].join(" ")
          elsif argument.multiple
            mapped_args[argument.name] = args[i...args.size]
          else
            mapped_args[argument.name] = args[i]
          end
        end
      end

      mapped_args
    end

    def required_args_provided?(mapped_args)
      @provided_required_args = true
      @arguments.each do |argument|
        if argument.required && !mapped_args[argument.name]?
          @provided_required_args = false
        end
      end
      @provided_required_args
    end

    private def clear_state
      @buffer = ""
      @in_arg = false
      @in_opt = false
      @in_splat = false
      @in_multi = false
    end

    private def add_arg
      if @in_splat && @in_multi
        raise Exception.new("Error at index #{@i} - param is both splat and multiple")
      end

      arg = Argument.new
      arg.name = @buffer
      arg.required = !@in_opt
      arg.multiple = @in_multi
      arg.splat = @in_splat

      @arguments << arg

      clear_state
    end

    private def parse_args
      @i = 0
      @end = @string.size
      
      clear_state

      while @i < @end
        case @string[@i]
        when '<'
          @in_arg = true
          @in_opt = false
        when '>'
          add_arg
        when '['
          @in_arg = true
          @in_opt = true
        when ']'
          add_arg
        when '.'
          if @in_arg && !@buffer.empty?
            eq = @string[@i] == '.' && @string[@i + 1] == '.' && @string[@i + 2] == '.'

            if eq
              @i += 2
              @in_multi = true
            end
          end
        when '*'
          @in_splat = true if @in_arg && !@buffer.empty?
        when ' '
        else
          if @in_arg
            @buffer += @string[@i]
          end
        end

        @i += 1
      end

      if !@buffer.empty? && @in_arg
        add_arg
      end

      clear_state
    end
  end

  class Command
    getter signature : Signature
    getter purpose : String
    
    @block : Hash(String, String | Array(String)) -> Nil

    def initialize(signature : String, @purpose, @block)
      @signature = Signature.new(signature)
      @arg_map = Hash(String, String | Array(String)).new # Must initialize to please the compiler
    end

    def map_args(args = ARGV)
      args = args.dup
      args.shift?
      @arg_map = @signature.map_args args
    end

    def required_args_provided?
      @signature.required_args_provided? @arg_map
    end

    def help
      str = "\n"
      str += "Usage: punch #{@signature.string}"
      str += "\n"
    end

    def run
      @block.call @arg_map
    end
  end

  def punch(signature : String, purpose : String, &block : Hash(String, String | Array(String)) -> Nil)
    @@commands << Command.new(signature, purpose, block)
  end

  def general_help
    str = "\n"
    str += "  punch v#{Punch::VERSION}/crystal\n\n"
    str += "  #{"Commands".colorize.mode(:bold)}:\n"

    @@commands.each do |cmd|
      str += "    #{cmd.signature.string}\n"
      if cmd.purpose
        str += "      #{cmd.purpose.colorize(:dark_gray)}\n"
      end
    end

    str += "\n"
  end

  def run(args = ARGV)
    command = args[0]?
    matched = @@commands.find { |c| c.signature.command == command } if command

    if matched
      matched.map_args(args)
      if matched.required_args_provided?
        matched.run
      else
        puts matched.help
      end
    else
      puts general_help
    end
  end
end