module ProcessingFramework 
	require "clamp"
	class CommandLineHelper  < Clamp::Command
		# shared options
		#@config = nil
  		option ["-b", "--basename"], "basename", "The basename of the data to be processed. For example npp.14300.1843 .  Appended to --outputdir if included."
#		option ["-i", "--input"], "input", "The source directory. If --basename is included, it is appended to this.", :required => true
		option ["-o", "--output"], "output", "The output directory. If --basename is included, it is appended to this.", :required => true
		option ["-t", "--tempdir"], "output", "The temp directory, used for working space. A sub directory will made inside this named after the basename.",  :environment_variable => "PROCESSING_TEMPDIR", :required => true

  		def execute
			raise "CommandLineHelper should not be instatiated directly." 
    		end

  	end
end

