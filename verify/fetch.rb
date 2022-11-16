#!/usr/bin/env ruby
STDIN.readlines.each do |host|
	host.chomp!
	puts "Doing: #{host}"
	system("mkdir -vp #{host}")
	system("scp -q -r #{host}:/opt/gina/sandy-utils-1.7.1-20201216153420/config #{host}/")
	#system("diff -r template/1.6.15 #{host}/1.6.15")  
end
