module Otoku
  module Sorting
    CHOICES = {
      "creation date" => :creation,
      "name" => :name,
      "entry type" => :flame_type,
      "length" => :length,
    }
    
    # A simple sorting decorator
    class Decorator
      DEFAULT_FIELD = :creation
      attr_accessor :field
      attr_accessor :flip

      def initialize
        @field, @flip, @enum = DEFAULT_FIELD, false, []
      end
      
      # Use like so
      # @sorter.apply(array).each...
      def apply(to_enum)
        @enum = to_enum
        self
      end
    
      def method_missing(*a, &blk) #:nodoc
        sorted_enum.send(*a, &blk)
      end
    
      def is_a?(smth) #:nodoc
        @enum.is_a?(smth)
      end
      
      def respond_to?(smth) #:nodoc
        super(smth) || @enum.respond_to?(smth)
      end
      
      private
        def sorted_enum
          sorted = @enum.sort do |a,b|  
            begin
              a.send(field) <=> b.send(field)
            rescue NoMethodError
              a.send(DEFAULT_FIELD) <=> b.send(DEFAULT_FIELD)
            end
          end
          
          flip ? sorted.reverse : sorted
        end
    end
  end
end