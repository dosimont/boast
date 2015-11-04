module BOAST

  module FORTRANRuntime
    include CompiledRuntime
    alias create_module_file_source_old create_module_file_source

    def create_module_file_source
      push_env(:use_vla => false)
      create_module_file_source_old
      pop_env(:use_vla)
    end

    def method_name
      return @procedure.name + "_"
    end

    def line_limited_source
      s = ""
      @code.rewind
      @code.each_line { |line|
        if line.match(/^\s*!\$/) then
          if line.match(/^\s*!\$(omp|OMP)/) then
            chunks = line.scan(/.{1,#{FORTRAN_LINE_LENGTH-7}}/)
            s += chunks.join("&\n!$omp&") + "\n"
          else
            chunks = line.scan(/.{1,#{FORTRAN_LINE_LENGTH-4}}/)
            s += chunks.join("&\n!$&") + "\n"
          end
        elsif line.match(/^\w*!/) then
          s += line
        else
          chunks = line.scan(/.{1,#{FORTRAN_LINE_LENGTH-2}}/)
          s += chunks.join("&\n&") + "\n"
        end
      }
      return s
    end

    def fill_library_source
      get_output.print line_limited_source
    end

    def create_procedure_call_parameters
      params = []
      @procedure.parameters.each { |param|
        if param.dimension then
          params.push( param.name )
        else
          params.push( "&"+param.name )
        end
      }
      return params
    end

  end

end
