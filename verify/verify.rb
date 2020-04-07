#!/usr/bin/env ruby
STDIN.readlines.each do |host|
	host.chomp!
	puts "Doing: #{host}"
	#system("mkdir #{host}")
	#system("scp -q -r #{host}:/hab/pkgs/uafgina/sandy-utils/* #{host}/")
	system("diff -r template/1.6.15 #{host}/1.6.15")  
end
