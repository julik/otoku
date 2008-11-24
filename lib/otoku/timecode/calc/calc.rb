module Juliks
  class Calc
    class Op; end
    def self.op(shortcut, &blk)
      c = Class.new(Op)
      c.send(:define_method, :to_s) { shortcut }
      if blk.arity == 2
        c.send(:define_method, :apply) { | a, b | blk.call(a,b) }
      else
        c.send(:define_method, :apply) { | a | blk.call(a) }
      end
      c.send(:define_method, :==) { | o | o.class == self.class }
      c
    end
  
    class ParseError < RuntimeError; end
    class NoDoubleOps < ParseError; end
    class InvalidAtom < ParseError; end
  
    Plus = op('+') { |a,b| a + b }
    Min = op('-') {|a, b| a - b }
    Mult = op('*') {|a, b| a * b }
    Div = op('/') {|a,b| a / b }
    Exp = op('^') {|a, b| a**b }
    PrefixMin = op('-') {|a| a * -1 }
    PrefixPlus = op('+') { |a| a }
    PrefixNegate = op('!') {|a| a**2 }
  
    class Atom
      include Comparable
      attr_reader :value
      def initialize(value)
        @value = value.to_i
      end
      def to_s; @value.to_s; end
      def <=>(o); value <=> o.value; end
    end
  
    OPERATORS = {
      '+' => Plus,
      '-' => Min,
      '*' => Mult,
      '/' => Div,
      '^' => Exp,
    }
  
    PREFIXES = {
      '-' => PrefixMin,
      '+' => PrefixPlus
    }
  
    PEMDAS = [
      # Parentheses are parsed out
      OPERATORS['^'],
      OPERATORS['*'],
      OPERATORS['/'],
      OPERATORS['+'],
      OPERATORS['-'],
    ]
  
    VALID_ATOM = /^(\d{1,})$/
  
    attr_accessor :buffer, :stack
    def initialize
      @buffer, @stack = '', []
    end
  
    def to_s
      "(%s)" % @stack.map{|e| e.to_s}.join('')
    end
  
    # Compute the value of the contained stack and return it
    def value
      # We respect the order of operations, so instead of walking the stack
      # in the linear fashion we collapse the elements
    
      # subexpressions and atoms
      cstack = @stack.map{|e| e.respond_to?(:value) ? e.value : e}
    
      # prefixes
      PREFIXES.values.each do | pop_class |
        cstack.each_with_index do | elem, index |
          if elem.is_a?(pop_class)
            cstack[index..index+1] = elem.apply(cstack[index+1])
          end
        end
      end
    
      # PEMDAS
      PEMDAS.each do | op_class |
        cstack.each_with_index do | elem, index |
          if elem.is_a?(op_class)
            cstack[index-1..index+1] = elem.apply(cstack[index -1], cstack[index+1])
          end
        end
      end
      cstack.pop
    end
  
    def parse(io)
      @buffer = ''
      until io.eof?
        c = io.getc.chr.strip
        parse_char(c)
      end
    
      # Last element if needed
      consume_atom
      self
    end
  
    def parse_char(c)
      # Parentheses are handle outside of the stack logic - we just
      # create a subcalculator for them
      if c == '('
        @stack << self.class.new.parse(io)
      elsif c == ')'
        consume_atom
        return self
      elsif OPERATORS.keys.include?(c) && (@stack[-1].is_a?(Atom) || !@buffer.empty?)
        raise "No double ops" if (@stack[-1].is_a?(Op) && @buffer.empty?)
        consume_atom
        @stack << OPERATORS[c].new
      # For prefix min and prefix plus
      elsif PREFIXES.keys.include?(c)
        @stack << PREFIXES[c].new
      elsif OPERATORS.keys.include?(c)
        raise ParseError, "Operator can only be present after an atom"
      else
        @buffer << c
      end
    end
    
    def consume_atom
      put_atom(@buffer); @buffer = ''
    end
    
    def put_atom(str)
      return if str.empty?
      raise InvalidAtom,"#{str} is not a valid atom" unless valid_atom?(str)
      @stack << Atom.new(str)
    end
  
    def valid_atom?(s)
      !!(s =~ VALID_ATOM)
    end
  
    def trace(m); end
  end
  
  if __FILE__ == $0
    require 'test/unit'
    require 'stringio'
    require 'rubygems'
    require 'flexmock'
    require 'flexmock/test_unit'

    module TH
      def setup
        @c = Calc.new
      end
  
      def parse(str)
        @c.parse(StringIO.new(str))
      end
  
      def parse_and_calc(str)
        parse(str).value
      end
    end

    class CalcTest < Test::Unit::TestCase
      include TH
      def test_valid_atom
        assert_equal false, @c.valid_atom?("bghhjt")
        assert_equal false, @c.valid_atom?("")
        assert_equal false, @c.valid_atom?(" ")
        assert_equal true, @c.valid_atom?("123")
      end
    
      def test_put_atom
        @c.put_atom("123")
        assert_equal [Calc::Atom.new('123')], @c.stack
      end
    
      def test_put_atom_with_empty_string_does_nothing
        @c.put_atom('')
        assert_equal [], @c.stack
      end
    
      def test_put_atom_with_invalid_text_raises
        assert_raise(Calc::InvalidAtom) { @c.put_atom("!$$$#*()(!@)}")}
        @c.put_atom('')
        assert_equal [], @c.stack
      end
    end
  
    class ParseTest < Test::Unit::TestCase
      include TH
      def test_parse_one
        assert_equal [Calc::Atom.new('1')], parse('1').stack
      end
    
      def test_parse_zeroes
        assert_equal [Calc::Atom.new('0')], parse('0' * 400).stack
      end
    
      def test_prefix_min_one_parsed_as_such
        assert_equal [Calc::PrefixMin.new, Calc::Atom.new('1')], parse('-1').stack
      end
    
      def test_prefix_min_parsed_when_followed_by_prefix_plus
        assert_equal [Calc::PrefixMin.new, Calc::PrefixPlus.new, Calc::Atom.new('1')], parse('-+1').stack
      end
  
      def test_prefix_plus_parsed_as_such
        assert_equal [Calc::PrefixPlus.new, Calc::Atom.new('1')], parse('+1').stack
      end
  
      def test_one_parsed_as_one
        assert_equal [Calc::Atom.new('1')], parse('1').stack
      end
  
      def test_one_plus_ten_parsed_properly
        assert_equal [Calc::Atom.new('1'), Calc::Plus.new, Calc::Atom.new(10)], parse('1 + 10').stack
      end
    end
  
  
    calc = Proc.new do | s| 
      calculator = Calc.new.parse(StringIO.new(s))
      puts "#{s} parses as #{calculator} and evaluates to #{calculator.value}"
    end

    puts "This is ze calculator. Some examples:"
    calc.call "-1"
    calc.call "1-1"
    calc.call "1+-1"
    calc.call "1+40"
    calc.call "10*-1"
    calc.call "2^3"
  end
end