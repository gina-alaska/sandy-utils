class SatDataFileQuickScat < SatDataFileBase
  def SatDataFileQuickScat.guess(x)
    # q1.20060817.2211.gz
    return true if (File.basename(x)[0, 3] == 'q1.' && File.basename(x).length == 19)
    false
  end

  def initialize(x)
    super(x)
    @platform_type = 'quickscat'
    @platform =  @name_bits[0]

    ##
    # extract the date
    bits = @name_bits
    date_parts  =  bits[1].scan(/(\d\d\d\d)(\d\d)(\d\d)/)[0]
    time_part =  bits[2].scan(/(\w\w)(\w\w)/)[0]

    foo = Time.utc(date_parts[0].to_i, date_parts[1].to_i, date_parts[2].to_i, time_part[0].to_i, time_part[1].to_i, 0, 0)

    @date_tm = foo
    @date = @date_tm.strftime('%y%j.%H%M')
    @mysql_dt =  @date_tm.strftime('%Y-%m-%d %H:%M:%S')
    ## time done..

    # Get the type..
    @type =  'unknown'
    @encoding = 'gz'
    # /projects/UAFGINA/a1/2003/154/a1.03154.0125.pds.bz2
    @archive_path = '/UAFGINA/' + @platform + @date_tm.strftime('/%Y/%j/')
    @url = @path = @archive_path = @archive_path + @name
  end
end
