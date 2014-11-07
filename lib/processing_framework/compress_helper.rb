module ProcessingFramework 
	class CompressHelper 
		def CompressHelper.uncompress( x )
	        	case (x.split(".").last)
                		when "gz"
                        		system("gunzip", x)
                        		return File.basename(x, ".gz")
                		when "bz2"
                        		system("bunzip2", x)
                        		return File.basename(x, ".bz2")
				else
					return x
			end
		end
	end
end

