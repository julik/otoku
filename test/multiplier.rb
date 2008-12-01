original = File.dirname(__FILE__) + '/samples/Flame_Archive_Deel215_08Jul15_1036.xml'
require 'fileutils'

created = (10..500).map do | tome |
  cpy = File.dirname(__FILE__) + '/samples/Flame_Archive_Deel%d_08Jul15_1036.xml' % tome
  begin
    FileUtils.cp original, cpy
    cpy
  rescue ArgumentError
    nil
  end
end.compact

at_exit {
  created.map {|c| File.unlink(c) }
}

sleep