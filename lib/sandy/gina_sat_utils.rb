module GinaSatUtils
  begin
    require 'json/ext'
  rescue LoadError
    require 'json/pure'
  end
end
