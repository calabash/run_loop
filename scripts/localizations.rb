#!/usr/bin/env ruby
PATH = File.expand_path(File.join("lib", "on_alert.js"))

lines = []

File.read(PATH).force_encoding("UTF-8").split($-0).each do |line|
  if line[/\[\".+\", \/.+\/\]/, 0]
     line.chomp!
     if line[-1,1] == ","
       line = line[0, line.length - 1]
     end
     lines << line
  end
end

puts lines.join(",#{$-0}")

