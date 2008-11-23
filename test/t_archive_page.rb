require File.dirname(__FILE__) + '/helper'

class ArchivePageTest < Camping::WebTest
  def setup
    @app_name_abbrev = 'Otoku'
    super
  end
  
  def test_get_with_no_archives
    begin
      old = Otoku::DATA_DIR
      Otoku.const_set(:DATA_DIR, File.dirname(__FILE__))
      
      get '/'
      asert_response :success
    ensure
      Otoku.const_set(:DATA_DIR, old)
    end
  end
end