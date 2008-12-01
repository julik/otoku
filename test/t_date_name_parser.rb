require File.dirname(__FILE__) + '/helper'
require 'otoku/data/date_parser'

class DateParserTest < Test::Unit::TestCase
  DATES = {
    "08Oct28_1107.xml" => DateTime.civil(2008, 10, 28, 11, 7),
    "08Oct28_1107" => DateTime.civil(2008, 10, 28, 11, 7),
    "08Jul15_1036" => DateTime.civil(2008, 7, 15, 10, 36),
  }
  
  def test_parsing
    DATES.each_pair do | string, result |
      assert_nothing_raised(string + " should parse without errors") do
        res = Otoku::Data::DateParser.parse(string)
        assert_not_nil res
        assert_equal result.year, res.year, "Should parse the proper year"
        assert_equal result.month, res.month, "Should parse the proper month"
        assert_equal result.day, res.day, "Should parse the proper day"
        assert_equal result.hour, res.hour, "Should parse the proper hour"
        assert_equal result.min, res.min, "Should parse the proper minute"
      end
    end
  end
  
  def test_parsing_should_properly_fail
    %w( archive1_08Jul_1209.xml abrwalg 123456 78 x zyh).each do | improper |
      assert_raise(Otoku::Data::DateParser::ParseError) { Otoku::Data::DateParser.parse(improper) }
    end
  end
end