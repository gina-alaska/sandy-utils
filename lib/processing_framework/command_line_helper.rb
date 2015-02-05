module ProcessingFramework
	require "clamp"
	require "fileutils"
	class CommandLineHelper  < Clamp::Command
		# shared options
		#@config = nil
  		option ["-b", "--basename"], "basename", "The basename of the data to be processed. For example npp.14300.1843 .  Appended to --outputdir if included."
#		option ["-i", "--input"], "input", "The source directory. If --basename is included, it is appended to this.", :required => true
		option ["-o", "--outdir"], "outdir", "The output directory. If --basename is included, it is appended to this.", :required => true
		option ["-t", "--tempdir"], "tempdir", "The temp directory, used for working space. A sub directory will made inside this named after the basename.",  :environment_variable => "PROCESSING_TEMPDIR", :required => true

  		def execute
			raise "CommandLineHelper should not be instatiated directly."
    		end


		#Perhaps not the best place for this - copies everything in the current directory to the directory at output
		def copy_output( output, save_glob="*")
			output += "/" if output[-1] != "/"
			FileUtils.mkdir_p(output)  if (!File.exists?(output))
                        Dir.glob(save_glob).each do |x|
                                puts("INFO: Copying #{x} to #{output}")
                                FileUtils.cp(x, output)
                        end
		end

  	end
end

