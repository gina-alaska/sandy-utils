class SatDataFileMODIS < SatDataFileBase
  def SatDataFileMODIS.guess(x)
    # a1.06257.2346.zero.gz
    return true if (File.basename(x)[0..1] == 'a1' || File.basename(x)[0..1] == 't1')
    false
  end

  def initialize(x)
    super(x)
    @platform_type = 'modis'
    @platform =  @name_bits[0]

    ##
    # extract the date
    bits = @name_bits
    date_part =  bits[1].scan(/(\d\d)(\d\d\d)/)[0]
    time_part =  bits[2].scan(/(\w\w)(\w\w)/)[0]

    foo = nil

    if (date_part[0] > '30')
      year =  date_part[0].to_i + 1900
      foo = Time.utc(year)
    else
      year =  date_part[0].to_i + 2000
      foo = Time.utc(year)
    end

    foo = foo + (date_part[1].to_i - 1) * 24 * 60 * 60 +  time_part[0].to_i * 60 * 60 + time_part[1].to_i * 60
    @date_tm = foo
    @date = @date_tm.strftime('%y%j.%H%M')
    @mysql_dt =  @date_tm.strftime('%Y-%m-%d %H:%M:%S')
    ## time done..

    # Get the type..
    @type = @name_bits[@name_bits.length - 2]
    @encoding = @name_bits[@name_bits.length - 1]
    # /projects/UAFGINA/a1/2003/154/a1.03154.0125.pds.bz2
    @archive_path = '/UAFGINA/' + @platform + @date_tm.strftime('/%Y/%j/')
    @url = @path = @archive_path = @archive_path + @name
  end
end
