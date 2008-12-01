# Parses Flame archive name part as a date
class Otoku::Data::DateParser
  RE = /(\d{2})(\w{3})(\d+)_(\d{2})(\d{2})(\.(\w+))?$/
  class ParseError < RuntimeError; end

  MONTHS = %w(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec).inject({}) do | table, mon |
    table.merge(mon => table.length + 1)
  end
  
  def self.parse(date)
    y, m, d, hour, minute = date.scan(RE).flatten
    raise ParseError, "Invalid archive date in filename #{date}" unless (y && m && d && hour && minute)

    y, m  = "20%s" % y, MONTHS[m] 
    raise ParseError, "Invalid month in #{date}" unless m

    DateTime.civil(*[y, m, d, hour, minute].map{|e| e.to_i})
  end
end