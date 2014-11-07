module ProcessingFramework 
	# just a sub, replace with something more useful later..
	class  ShellOutHelper
  		def ShellOutHelper.run_shell(s, verbose=false) 
                        puts("Running: #{s}") if (verbose)
                        start_time = Time.now
                        st = system(s)
                        puts("Done in #{(Time.now - start_time)/60.0}m.") if (verbose)
                        return st
    		end

                def ShellOutHelper.run(s,verbose=false)	
  			puts("Running: #{s.join(" ")}") if (verbose)
  			start_time = Time.now
  			st = system(*s)
  			puts("Done in #{(Time.now - start_time)/60.0}m.") if (verbose)
			return st
		end
  	end
end

