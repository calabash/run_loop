begin
  require 'pry'
  Pry.config.history.should_save = false
  Pry.config.history.should_load = false
  require 'pry-nav'
rescue LoadError => _

end
