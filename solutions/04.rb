module DSL
  class Variable
    attr_accessor :name, :value

    def initialize(name,value=0)
      @name = name
      @value = value
    end

    def to_s
      @name + ":" + @value
    end
  end

  class LanguageState
    attr_accessor :line_table,:line_pointer,:variables,:line_count

    def initialize
      @line_table = []
      @line_pointer = 0
      @variables = {}
      @line_count = 0
    end

    def current_line
      @line_table[@line_pointer]
    end

    def execute_line(line)
      *args = self,*line.arguments
      line.statement.call *args
    end
  end

  class Language
    Line = Struct.new :statement,:arguments,:is_instruction

    def instance_exec
      super

      while @state.line_pointer < @state.line_table.count do
        line = @state.current_line
        @state.execute_line line
        @state.line_pointer += 1
      end

      @initial_variables.collect do |variable_name|
        @state.variables[variable_name].value
      end
    end

    def method_missing(method, *args, &block)
      method
    end

    protected

    def initialize(variables,directives)
      @state = LanguageState.new
      @initial_variables = variables
      register_variables variables
      register_directives directives
    end

    private

    def register_directives(directives)
      directives.each do |directive|
        register_directive directive
      end
    end

    def register_variables(variables)
      variables.each do |variable|
        register_variable Variable.new variable
      end
    end

    def register_directive(directive)
      register_directive_variables directive
        self.define_singleton_method(directive.name) do |*args|
          if directive.is_instruction then
            @state.line_count += 1
            line = Line.new directive.statement ,args ,directive.is_instruction
            @state.line_table.push line
          else
            directive.statement.call @state,*args
          end
        end
    end

    def register_directive_variables(directive)
      directive.directive_variables.each do |variable|
        @state.variables[variable.name] = variable
      end
    end

    def register_variable(variable)
      @state.variables[variable.name] = variable
      self.define_singleton_method(variable.name) do
        @state.variables[variable.name]
      end
    end
  end

  class Directive
    def name
      nil
    end

    def statement
      nil
    end

    def directive_variables
      []
    end

    def is_instruction
      true
    end
  end
end

module Asm
  module Directives
    class MoveDirective < DSL::Directive
      def name
        :mov
      end

      def statement
        ->(language_state,register,value) do
          register.value = value
        end
      end
    end

    class IncrementDirective < DSL::Directive
      def name
        :inc
      end

      def statement
        ->(language_state,register,value = 1) do
          if value.is_a? DSL::Variable then
            register.value += value.value
          else
            register.value += value
          end
        end
      end
    end

    class DecrementDirective < DSL::Directive
      def name
        :dec
      end

      def statement
        ->(language_state,register,value = 1) do
          if value.is_a? DSL::Variable then
            register.value -= value.value
          else
            register.value -= value
          end
        end
      end
    end

    class CompareDirective < DSL::Directive
      def name
        :cmp
      end

      def statement
        ->(language_state,register,value = 1) do
          if value.is_a? DSL::Variable then
            language_state.variables["bool"].value = register.value - value.value
          else
            language_state.variables["bool"].value = register.value - value
          end
        end
      end

      def directive_variables
        comparison_register = DSL::Variable.new "bool", 0
        [comparison_register]
      end
    end

    class LabelDirective < DSL::Directive
      def name
        :label
      end

      def statement
        ->(language_state,label) do
          pointer = language_state.line_count - 1
          language_state.variables["labels"].value[label] = pointer
        end
      end

      def directive_variables
        label_aliases = DSL::Variable.new "labels", {}
        [label_aliases]
      end

      def is_instruction
        false
      end
    end

    class JumpDirective < DSL::Directive
      def initialize(name, check = ->(reg){true},clear_cmp = false)
        @name = name
        @check = check
      end

      def name
        @name
      end

      def statement
        ->(language_state,label) do
          if !@check.call language_state.variables["bool"].value then return end
          ptr = if label.is_a? Symbol then
            language_state.variables["labels"].value[label]
          else
            label
          end
          language_state.line_pointer = ptr
        end
      end
    end
  end

  def Asm.math_directives
    [Directives::MoveDirective.new,
     Directives::IncrementDirective.new,
     Directives::DecrementDirective.new,
     Directives::CompareDirective.new,
     Directives::LabelDirective.new]
  end

  def Asm.jump_directives
    [(Directives::JumpDirective.new :jmp),
     (Directives::JumpDirective.new :je, ->(x) { x == 0 }),
     (Directives::JumpDirective.new :jne,->(x) { x != 0 }),
     (Directives::JumpDirective.new :jl, ->(x) { x < 0 } ),
     (Directives::JumpDirective.new :jle,->(x) { x <= 0 }),
     (Directives::JumpDirective.new :jg, ->(x) { x > 0 } ),
     (Directives::JumpDirective.new :jge,->(x) { x>=0 } )]
  end

  def Asm.asm
    variables =  ["ax","bx","cx","dx"]
    directives = math_directives + jump_directives
    DSL::Language.new variables,directives
  end
end


lang = Asm.asm
vars = lang.instance_exec do
  mov ax, 40
  mov bx, 32
  label cycle
  cmp ax, bx
  je finish
  jl asmaller
  dec ax, bx
  jmp cycle
  label asmaller
  dec bx, ax
  jmp cycle
  label finish
end

puts vars.to_s