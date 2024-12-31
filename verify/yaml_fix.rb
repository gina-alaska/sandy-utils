require "psych"
require "pp"
ARGV.each do | item|
  yml = File.open(item) {|fd|Psych.load(fd) } 
  File.open(item, "w") {|fd| Psych.dump(yml, fd) }
end
