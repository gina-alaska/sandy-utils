#!/usr/bin/env ruby
=begin
----------------------------
- base.rb
- provides basic information about gina datafiles.
=end


class SatDataFile
	def initialize(x)
		raise "SatDataFile isn't ment to be created directly, use SatDataFile.get(x)"
	end
	def SatDataFile.get(x)
	       return SatDataFileDMSP.new(x) if (SatDataFileDMSP.guess(x) )
	       return SatDataFileNOAA.new(x) if (SatDataFileNOAA.guess(x) )
               return SatDataFileGOES.new(x) if (SatDataFileGOES.guess(x) )
               return SatDataFileLANDSAT.new(x) if (SatDataFileLANDSAT.guess(x) )
	       return SatDataFileNPP.new(x) if (SatDataFileNPP.guess(x) )
               return SatDataFileMODIS.new(x) if (SatDataFileMODIS.guess(x) )
	       return SatDataFileQuickScat.new(x) if (SatDataFileQuickScat.guess(x))
	       return SatDataFileSV.new(x) if (SatDataFileSV.guess(x) )
               return nil
	end

	def SatDataFile.valid?( x )
	       return true if (SatDataFileDMSP.guess(x) )
	       return true if (SatDataFileNOAA.guess(x) )
               return true if (SatDataFileGOES.guess(x) )
               return true if (SatDataFileLANDSAT.guess(x) )
               return true if (SatDataFileMODIS.guess(x) )
	       return true if (SatDataFileNPP.guess(x) )
	       return true if (SatDataFileQuickScat.guess(x))
	       return true if (SatDataFileSV.guess(x) )
               return false
	end
end

class SatDataFileBase
        attr_reader :type
        attr_reader :encoding
        attr_reader :md5
        attr_reader :path
        attr_reader :platform_type
        attr_reader :platform
        attr_reader :data_type
        attr_reader :name
        attr_reader :full_path
        attr_reader :date_tm
        attr_reader :date
        attr_reader :url
        attr_reader :md5
        attr_reader :size
        attr_reader :mysql_dt
	attr_reader :archive_path
	attr_reader :scene_id


	def initialize ( x) 
                @full_path = x
                @name = File.basename(x)
		@name_bits = @name.split(".")
		@ext = @name_bits.last
                @encoding = @ext
		@scene_id=nil
		read_md5()
	end

	def SatDataFileBase.sumon( x) 
		return SatDataFileDMSP.new(x) if (SatDataFileDMSP.guess(x) )
		return SatDataFileNOAA.new(x) if (SatDataFileNOAA.guess(x) )
		return SatDataFileGOES.new(x) if (SatDataFileGOES.guess(x) )
		return SatDataFileLANDSAT.new(x) if (SatDataFileLANDSAT.guess(x) )
		return SatDataFileMODIS.new(x) if (SatDataFileMODIS.guess(x) )		
		return nil
	end

	#this is stupid, should just alias.
        def SatDataFileBase.get( x)
		return SatDataFileBase.sumon( x)
        end


        def read_size ( )
                @size = (File.size(@full_path))
        end

        def read_md5( )
                if (!File.size?(@full_path+".md5"))
                        @md5="unknown"
                else
			fl = IO.readlines(@full_path+".md5")
                        @md5 = fl[0].split(/\s+/)[0]
                end

        end

        def set_md5(md5)
                @md5 = md5;
                fl = File.new( @full_path  + ".md5",
                                File::WRONLY|File::CREAT|File::TRUNC, 0660);
                fl.puts("#{md5}");
                fl.close();
        end


        def to_s
                return ( @name + ":" + @realname )
        end

        def check
          compress = true
          case (@encoding)
                when "bz2"then
                        fdin =IO.popen("bunzip2 -t #{@full_path}");
                        fpid, status = Process.wait2();
                        compress = false if ( status != 0 )
                when "gz" then
                        fdin =IO.popen("gunzip -t #{@full_path}");
                        fpid, status = Process.wait2();
                        compress = false if ( status != 0 )
                else
                        compress false
          end

          return compress

        end

	def pp 
		puts("type = '#{type}'")
        	puts("encoding ='#{@encoding}'") 
        	puts("md5 ='#{@md5}'")
        	puts("path ='#{@path}'") 
        	puts("platform_type ='#{@platform_type}'") 
        	puts("platform ='#{@platform}'")
        	puts("data_type ='#{@date_type}'") 
        	puts("name ='#{@name}'") 
        	puts("full_path ='#{@full_path}'") 
        	puts("date_tm ='#{@date_tm}'") 
        	puts("date ='#{@date}'") 
        	puts("url ='#{@url}'") 
        	puts("md5 ='#{@md5}'")
        	puts("size ='#{@size}'") 
        	puts("mysql_dt ='#{@mysql_dt}'") 
        	puts("archive_path ='#{@archive_path}'") 
        	puts("scene_id ='#{@scene_id}'")

	end
end


require_relative "modis"
require_relative "dmsp"
require_relative "noaa_poes"
require_relative "landsat"
require_relative "snpp.rb"
require_relative "sv_bundle"
require_relative "goes"
require_relative "quicks"
