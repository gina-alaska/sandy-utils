class SatDataFileSV < SatDataFileBase
                ##
                # (sceneid)-srcdata.tar.gz
                # 0123456789012
        attr_reader :toc

        def initialize ( x )
                super(x)
                @type  = "tar"
                @platform_type = "sv_archive"
                @platform =  "sv_archive"
                @data_type = "sv_archive"
                @date_tm = Time::at(0)
                @date =  @date_tm.strftime("%y%j.%H%M")
                @mysql_dt =  @date_tm.strftime( "%Y-%m-%d %H:%M:%S")

                ##
                # set sceneids
                @scene_id = File.basename(x,"-srcdata.tar.gz")
                @archive_path = "/UAFGINA/sv_scenes/"

                scene_id_split = @scene_id.split(".")
                if ( scene_id_split.length > 3 )
                        @archive_path = @archive_path + scene_id_split[0,3].join("/") + "/" + @scene_id + "/"
                else
                        @archive_path = @archive_path + "/misc/" + @scene_id + "/"
                end

                puts("Archive path = \"#{@archive_path}\"\n")
                @url = @path = @archive_path = @archive_path + @name
                puts("Final path = \"#{@archive_path}\"\n")

                ##
                # Read the Toc file, if it exists..
                readTOC()
        end

        def readTOC
                @toc = "no TOC file exists."
                @toc = IO.readlines(@full_path+".TOC") if ( File.readable?(@full_path+".TOC") )
        end

        def SatDataFileSV.guess(x)
                pieces = File.basename(x).split(".")
                return false if (SatDataFileLANDSAT.guess(x))
                return true if ( File.basename(x) == File.basename(x,"-srcdata.tar.gz") + "-srcdata.tar.gz")
                return false
        end

end
