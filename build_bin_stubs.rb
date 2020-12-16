#!/usr/bin/env ruby
# A simple tool to build bin stubs for the sandy utils
require "fileutils"


def get_version() 
	File.readlines(File.dirname(__FILE__)+"/VERSION").join().chomp
end



def generate_bin_stub(path, version)

	script_name = "/opt/gina/sandy-utils-#{version}/tools/" + File.basename(path)

 	lines = []
	lines << "#!/bin/bash"
 	#lines << "export GEM_HOME=\"/opt/gina/sandy-utils-#{version}/vendor/bundle\""
	#lines << "export GEM_PATH=\"/opt/gina/sandy-utils-#{version}:/opt/gina/sandy-utils-$VERSION/vendor/bundle\""
	#lines << "export PATH=/opt/gina/sandy-utils-#{version}/bin"
        #lines << "export LD_LIBRARY_PATH=/opt/gina/sandy-utils-#{version}/lib64:/opt/gina/sandy-utils-#{version}/lib"
        #lines << "source /opt/gina/sandy-utils-#{version}/bin/activate"
        lines << "source /opt/gina/sandy-utils-#{version}/env.sh"
	lines << "if [[ -f $TSCANROOT/etc/tscan.bash_profile ]]; then"
	lines << "    source $TSCANROOT/etc/tscan.bash_profile"
	lines << "fi"
	lines << "exec #{script_name}.real $@"
	
	File.open(script_name, "w") do |fd|
		fd.puts(lines.join("\n"))
	end
	FileUtils.chmod "a=x", script_name
	FileUtils.cp path, script_name +".real"
	FileUtils.chmod "a=x", script_name +".real"
end

ARGV.each do |item|
        generate_bin_stub(item, get_version())
end
