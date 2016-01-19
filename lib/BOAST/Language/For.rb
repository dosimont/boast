module BOAST

  class For < ControlStructure

    attr_reader :iterator
    attr_reader :begin
    attr_reader :end
    attr_reader :step
    attr_accessor :block

    def initialize(i, b, e, options={}, &block)
      default_options = {:step => 1}
      default_options.update( options )
      @options = options
      @iterator = i
      @begin = b
      @end = e
      @step = default_options[:step]
      @operator = "<="
      @block = block
      @openmp = default_options[:openmp]
      if @openmp then
        if @openmp.kind_of?(Hash) then
          @openmp = OpenMP::For(@openmp)
        else
          @openmp = OpenMP::For({})
        end
      end
      begin
        push_env( :replace_constants => true )
        if @step.kind_of?(Variable) then
          step = @step.constant
        elsif @step.kind_of?(Expression) then
          step = eval "#{@step}"
        else
          step = @step.to_i
        end
        @operator = ">=" if step < 0
      rescue
        STDERR.puts "Warning could not determine sign of step (#{@step}) assuming positive" if [C, CL, CUDA].include?( lang ) and debug?
      ensure
        pop_env( :replace_constants )
      end
    end

    def annotation
      return { :iterator => @iterator.to_s, :begin => @begin.to_s, :end => @end.to_s, :step => @step.to_s, :operator => @operator.to_s }
    end

    def get_c_strings
      return { :for => '"for (#{i} = #{b}; #{i} #{o} #{e}; #{i} += #{s}) {"',
               :end => '"}"' }
    end

    def get_fortran_strings
      return { :for => '"do #{i} = #{b}, #{e}, #{s}"',
               :end => '"end do"' }
    end

    alias get_cl_strings get_c_strings
    alias get_cuda_strings get_c_strings

    eval token_string_generator( * %w{for i b e s o})
    eval token_string_generator( * %w{end})

    def to_s
      s = for_string(@iterator, @begin, @end, @step, @operator)
      return s
    end

#    def u(s = 2)
#      return [For::new(@iterator, @begin, @end - (@step*s - 1), @options.dup.update( { :step => (@step*s) } ), &@block),
#              For::new(@iterator, @begin.to_var + ((@end - @begin + 1)/(@step*s))*(@step*s), @end, @options, &@block) ]
#    end
#
    def unroll(*args)
      raise "Block not given!" if not @block
      push_env( :replace_constants => true )
      begin
        if @begin.kind_of?(Variable) then
          start = @begin.constant
        elsif @begin.kind_of?(Expression) then
          start = eval "#{@begin}"
        else
          start = @begin.to_i
        end
        if @end.kind_of?(Variable) then
          e = @end.constant
        elsif @end.kind_of?(Expression) then
          e = eval "#{@end}"
        else
          e = @end.to_i
        end
        if @step.kind_of?(Variable) then
          step = @step.constant
        elsif @step.kind_of?(Expression) then
          step = eval "#{@step}"
        else
          step = @step.to_i
        end
        raise "Invalid bounds (not constants)!" if not ( start and e and step )
      rescue Exception => ex
        if not ( start and e and step ) then
          pop_env( :replace_constants )
          return pr(*args) if not ( start and e and step )
        end
      end
      pop_env( :replace_constants )
      range = start..e
      @iterator.force_replace_constant = true
      range.step(step) { |i|
        @iterator.constant = i
        @block.call(*args)
      }
      @iterator.force_replace_constant = false
      @iterator.constant = nil
    end

    def open
      @openmp.open if @openmp
      s=""
      s += indent
      s += to_s
      output.puts s
      increment_indent_level      
      return self
    end 

    def pr(*args)
      open
      if @block then
        @block.call(*args)
        close
      end
      return self
    end

    def close
      decrement_indent_level      
      s = ""
      s += indent
      s += end_string
      output.puts s
      @openmp.close if @openmp
      return self
    end

  end

end
