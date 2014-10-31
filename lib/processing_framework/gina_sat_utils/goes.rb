class SatDataFileGOES < SatDataFileBase
        ##
        # This class does goes stuff...
        def initialize ( x )
           super(x)
           @platform_type="goes"
           @platform =  @name_bits[@name_bits.length() -2]

           ##
           # extract the date
           date_part =  @name_bits[0].scan(/(\d\d\d\d)(\d\d)(\d\d)/)[0];
           time_part =  @name_bits[1].scan(/(\w\w)(\w\w)/)[0];
           year =  date_part[0].to_i;

           @date_tm = Time.utc(year, date_part[1].to_i, date_part[2].to_i,time_part[0].to_i,time_part[1].to_i,0,0);
           @date = @date_tm.strftime("%y%j.%H%M")
           @mysql_dt =  @date_tm.strftime( "%Y-%m-%d %H:%M:%S");
           @type = @name_bits[2]
           @encoding = @name_bits[4]
           @archive_path= "/UAFGINA/GOES/"+@platform+"/" + @date_tm.strftime("/%Y/%j/")
           @url = @path = @archive_path = @archive_path + @name
        end

        def SatDataFileGOES.guess(x)
                #20060403.0100.hi.g10.gz
                pieces = File.basename(x).split(".")
                return true if ( pieces[pieces.length() -2][0..3] == "g10" )
                return true if ( pieces[pieces.length() -2][0..3] == "g11" )
                return false
        end
end
