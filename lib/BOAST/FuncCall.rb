module BOAST

  class FuncCall
    include BOAST::Arithmetic
    include BOAST::Inspectable

    @return_type
    @options
    def self.parens(*args,&block)
      return self::new(*args,&block)
    end

    attr_reader :func_name
    attr_reader :args
    attr_accessor :prefix

    def initialize(func_name, *args)
      @func_name = func_name
      if args.last.kind_of?(Hash) then
        @options = args.last
        @args = args[0..-2]
      else
        @args = args
      end
      @return_type = @options[:returns] if @options
    end

    def to_var
      if @return_type then
        if @return_type.kind_of?(Variable)
          return @return_type.copy("#{self}")
        else
          return Variable::new("#{self}", @return_type)
        end
      end
      return nil
    end
      
    def to_s
      return self.to_s_fortran if BOAST::get_lang == FORTRAN
      return self.to_s_c if [C, CL, CUDA].include?( BOAST::get_lang )
    end

    def to_s_fortran
      s = ""
      s += @prefix if @prefix
      s += "#{func_name}(#{@args.join(", ")})"
    end

    def to_s_c
      s = ""
      s += @prefix if @prefix
      s += "#{func_name}(#{@args.join(", ")})"
    end

    def print(final=true)
      s=""
      s += " "*BOAST::get_indent_level if final
      s += self.to_s
      s += ";" if final and [C, CL, CUDA].include?( BOAST::get_lang )
      BOAST::get_output.puts s if final
      return s
    end
  end

end