module BOAST

  extend TypeTransition
  
  module PrivateStateAccessor

    private
    def push_env(*args)
      BOAST::push_env(*args)
    end

    def pop_env(*args)
      BOAST::pop_env(*args)
    end

    def increment_indent_level(*args)
      BOAST::increment_indent_level(*args)
    end

    def decrement_indent_level(*args)
      BOAST::decrement_indent_level(*args)
    end

    def indent
      BOAST::indent
    end

    # Returns the symbol corresponding to the active architecture
    def get_architecture_name
      BOAST::get_architecture_name
    end

    # Returns the symbol corresponding to the active language
    def get_lang_name
      BOAST::get_lang_name
    end

    def annotate_number(*args)
      BOAST::annotate_number(*args)
    end

  end

  module_function

  # Returns the symbol corresponding to the active architecture
  def get_architecture_name
    case architecture
    when X86
      return :X86
    when ARM
      return :ARM
    when MPPA
      return :MPPA
    else
      return nil
    end
  end

  # Returns the symbol corresponding to the active language
  def get_lang_name
    case lang
    when C
      return :C
    when FORTRAN
      return :FORTRAN
    when CL
      return :CL
    when CUDA
      return :CUDA
    else
      nil
    end
  end

  @@output = STDOUT
  @@chain_code = false
  @@decl_module = false
  @@annotate_numbers = Hash::new { |h,k| h[k] = 0 }

  @@env = Hash::new{|h, k| h[k] = []}

  # Updates states and stores their value in a stack for later retrieval
  # @param [Hash] vars contains state symbols and values pairs
  # @yield states will be popped after the given block if any
  def push_env(vars = {}, &block)
    keys = []
    vars.each { |key, value|
      var = nil
      begin
        var = BOAST::class_variable_get("@@"+key.to_s)
      rescue
        BOAST::pop_env(*keys)
        raise "Unknown module variable #{key}!"
      end
      @@env[key].push(var)
      BOAST::class_variable_set("@@"+key.to_s, value)
      keys.push(key)
    }
    if block then
      begin
        block.call
      ensure
        BOAST::pop_env(*vars.keys)
      end
    end
  end

  # Pops the specified states values
  # @param vars a list of state symbols
  def pop_env(*vars)
    vars.each { |key|
      raise "Unknown module variable #{key}!" unless @@env.has_key?(key)
      ret = @@env[key].pop
      raise "No stored value for #{key}!" if ret.nil?
      BOAST::class_variable_set("@@"+key.to_s, ret)
    }
  end

  # Increments the indent level
  # @param [Integer] increment number of space to add
  def increment_indent_level(increment = get_indent_increment)
    set_indent_level( get_indent_level + increment )
  end

  # Decrements the indent level
  # @param [Integer] increment number of space to remove 
  def decrement_indent_level(increment = get_indent_increment)
    set_indent_level( get_indent_level - increment )
  end

  # Returns a string with as many space as the indent level.
  def indent
     return " "*get_indent_level
  end

  # Returns an annotation number for the given name. The number
  # is incremented for a given name is incremented each time this name is called
  def annotate_number(name)
    num = @@annotate_numbers[name]
    @@annotate_numbers[name] = num + 1
    return num
  end

  # Annotates an Object by inlining a YAML structure in a comment.
  # If object's class is part of the annotate list an indepth version of the annotation
  # will be generated.
  # @param [Object] a object to annotate
  def pr_annotate(a)
    name = a.class.name.gsub("BOAST::","")
    if annotate_list.include?(name) then
      description = nil
      if a.is_a?(Annotation) and a.annotate_indepth?(0) then
        description = a.annotation(0)
      end
      annotation = { "#{name}#{annotate_number(name)}" => description }
      Comment(YAML::dump(annotation)).pr
    end
  end


  # One of BOAST keywords: prints BOAST objects.
  # Annotates the given object.
  # Calls the given object pr method with the optional arguments.
  # @param a a BOAST Expression, ControlStructure or Procedure
  # @param args an optional list of parameters
  def pr(a, *args)
    pr_annotate(a) if annotate?
    a.pr(*args)
  end

  # One of BOAST keywords: declares BOAST Variables and Procedures.
  # Calls the decl method of each given objects.
  # @param list a list of parameters do declare
  def decl(*list)
    list.each { |d|
      d.decl
    }
  end

  # One of BOAST keywords: opens a BOAST ControlStructure or Procedure.
  # Calls the open method of the given object.
  # @param a the BOAST object to open
  def opn(a)
    a.open
  end

  # One of BOAST keywords: closes a BOAST ControlStructure or Procedure.
  # Calls the close method of the given object.
  # @param a the BOAST object to close
  def close(a)
    a.close
  end

  alias :Var :Variable
  alias :Dim :Dimension
  alias :Call :FuncCall

  class << self
    alias :Var :Variable
    alias :Dim :Dimension
    alias :Call :FuncCall
  end

  Var = Variable
  Dim = Dimension
  Call = FuncCall

  set_transition(Int, Int, :default, Int)
  set_transition(Real, Int, :default, Real)
  set_transition(Int, Real, :default, Real)
  set_transition(Real, Real, :default, Real)
  set_transition(Sizet, Sizet, :default, Sizet)
  set_transition(Sizet, Int, :default, Sizet)
  set_transition(Int, Sizet, :default, Sizet)

end

ConvolutionGenerator = BOAST

class Integer
  def to_var
    if self < 0 then
       v = BOAST::Variable::new("#{self}", BOAST::Int, :signed => true, :constant => self )
     else
       v = BOAST::Variable::new("#{self}", BOAST::Int, :signed => false, :constant => self )
    end
    v.force_replace_constant = true
    return v
  end
end

class Float
  def to_var
    v = BOAST::Variable::new("#{self}", BOAST::Real, :constant => self )
    v.force_replace_constant = true
    return v
  end
end

