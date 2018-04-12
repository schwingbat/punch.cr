module CLI
  alias RunBlock = Hash(String, String | Array(String)) -> Nil
  
  class Argument
    property name : String = ""
    property description : String = ""
    property required : Bool = true
    property multiple : Bool = false
    property splat : Bool = false
  end

  class Signature
    getter arguments = [] of Argument
    property string : String
    getter command : String

    @i : Int32 = 0
    @end : Int32 = 0
    @buffer = ""
    @in_arg = false
    @in_opt = false
    @in_splat = false
    @in_multi = false
    @in_flag = false

    def initialize(@string)
      @command = @string.split(" ").first
      parse_args
    end

    def map_args(args)
      mapped_args = Hash(String, String | Array(String)).new

      puts args.inspect

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
      @in_flag = false
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
          @in_splat = true if @in_arg
        when ' '
          if @in_arg
            @buffer += @string[@i]
          end
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
    getter purpose : String?
    
    @block : RunBlock?

    def initialize(signature : String, @purpose, @block)
      @signature = Signature.new(signature)
      @arg_map = Hash(String, String | Array(String)).new # Must initialize to please the compiler
    end
    
    # For use by the command definition block
    
    def initialize(signature : String)
      @signature = Signature.new(signature)
      @arg_map = Hash(String, String | Array(String)).new
    end
    
    def purpose(value : String)
      @purpose = value
    end
    
    def argument(name : String, *, description : String)
      if arg = @signature.arguments.find { |arg| arg.name == name }
        arg.description = description
      else
        raise Exception.new "No argument called #{name} exists in this command's signature"
      end
    end
      
    def run(&block : RunBlock)
      @block = block
    end
    
    # --------------------------------------

    def map_args(args = ARGV)
      args = args.dup
      args.shift?
      @arg_map = @signature.map_args args
    end

    def required_args_provided?
      @signature.required_args_provided? @arg_map
    end

    def help
      str = "\nUsage: punch #{@signature.string}\n"
      
      str += "\nArguments: (#{"*".colorize(:red)} required)\n"
      
      max = 0
      args = Array(Array(String)).new
      
      @signature.arguments.each do |arg|
        first = "  "
        
        if arg.required
          first += "* ".colorize(:red).to_s
        else
          first += "  "
        end
        
        first += arg.name
        
        max = first.size if first.size > max
        args << [first, arg.description]
      end
      
      args.each do |arg|
        leading, description = arg
        
        str += leading.ljust(max) + " -> ".colorize(:dark_gray).to_s + description + "\n"
      end
      
      str
    end

    def exec
      if @block.nil?
        raise Exception.new "Can't run command \"#{@signature.command}\" because no run block is defined."
      else
        @block.as(RunBlock).call @arg_map
      end
    end
  end

  def punch(signature : String, purpose : String, &block : RunBlock)
    @@commands << Command.new(signature, purpose, block)
  end
  
  def punch(signature, &block : Command -> Nil)
    cmd = Command.new(signature)
    yield cmd
    @@commands << cmd
  end

  def general_help
    String::Builder.build do |io|
      indent = "  "
      br = "\n"
      
      io << br
      io << indent + "punch v#{Punch::VERSION}/crystal" + br
      io << br
      io << indent + "How to read the command signatures:" + br
      io << indent * 2 + "- a <param> is required" + br
      io << indent * 2 + "- a [param] is optional" + br
      io << indent * 2 + "- a <*param>, [*param] means that any input after this point will be considered a single value" + br
      io << indent * 2 + "- a <param...> or [param...] means that any input after this point will be considered a list of values named `param`" + br
      io << br
      io << indent + "#{"Commands".colorize.mode(:bold)}" + br
      @@commands.each do |cmd|
        io << indent * 2 + cmd.signature.string.to_s + br
        if cmd.purpose
          io << indent * 3 + cmd.purpose.colorize(:dark_gray).to_s + br
        end 
      end
      io << br
    end
  end

  def run(args = ARGV)
    command = args[0]?
    matched = @@commands.find { |c| c.signature.command == command } if command

    if matched
      matched.map_args(args)
      if matched.required_args_provided?
        matched.exec
      else
        puts matched.help
      end
    else
      puts general_help
    end
  end
end