#!/usr/bin/env ruby
STDIN.readlines.each do |host|
	host.chomp!
	system("diff -r ../config #{host}/*/*/config")  
end
