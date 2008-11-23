class Builder::XmlMarkup
  def _start_tag(sym, attrs, end_too=false)
    @target << "<#{sym}"
    _insert_attributes(attrs)
    @target << " /" if end_too #HIER!!
    @target << ">"
  end
end
