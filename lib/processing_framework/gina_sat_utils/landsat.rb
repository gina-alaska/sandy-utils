class SatDataFileLANDSAT < SatDataFileBase
                ##
                # Landsat a bit different
                # L107001773189-srcdata.tar.gz
                # 0123456789012
        attr_reader :toc

        def initialize ( x )
                super(x)
                @type  = "tar"
                @platform_type = "landsat"
                @platform =  @name[0..1]
                @data_type = "landsat"
                @date_tm = Time.utc(@name[8..9].to_i, 1,1,0,0) + @name[10..12].to_i * 24*60*60
                @date =  @date_tm.strftime("%y%j.%H%M")
                @mysql_dt =  @date_tm.strftime( "%Y-%m-%d %H:%M:%S")

                ##
                # set sceneids
                #@scene_id = @name[0..12]
                bits = @name.split(".")
                bits.delete_at(bits.length-1)  #gz
                bits.delete_at(bits.length-1)  #tar
                @scene_id = bits.join(".").gsub("-srcdata","")

                ##
                # Path should look like:
                # /l1/p070/r017/y1973/L107001773189/L107001773189.tar.gz
                @archive_path = "/UAFGINA/landsat/"+@platform.downcase+"/" + "p" + @name[2..4] + "/" + "r" + @name[5..7] + @date_tm.strftime("/y%Y/")+"/" + @name[0..12] + "/"
                puts("Archive path = \"#{@archive_path}\"\n")
                @url = @path = @archive_path = @archive_path + @name
                puts("Final path = \"#{@archive_path}\"\n")

                ##
                # Read the Toc file, if it exists..
                @toc = "no TOC file exists."
                @toc = IO.readlines(@full_path+".TOC") if ( File.readable?(@full_path+".TOC") )
        end

        def SatDataFileLANDSAT.guess(x)
                pieces = File.basename(x).split(".")
                return false if (pieces[0][0..0] != "L")
                platform = pieces[0][1,1].to_i
                return false if ( platform < 1 || platform > 7)  #only landsat 1-7 are valid, pending ldcm..

                return true if ( pieces[0][0..0] == "L" && pieces[pieces.length-2] == "tar" && pieces[pieces.length-1] == "gz")
                return false
        end

        def readTOC
                @toc = "no TOC file exists."
                @toc = IO.readlines(@full_path+".TOC") if ( File.readable?(@full_path+".TOC") )
        end


end
