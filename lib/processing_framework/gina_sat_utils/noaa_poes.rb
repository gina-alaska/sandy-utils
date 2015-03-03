class SatDataFileNOAA < SatDataFileBase
  def SatDataFileNOAA.guess(x)
    # n17.06240.0010.avhrr.L1a.gz
    pieces = File.basename(x).split('.')
    return true if (pieces[3] == 'avhrr')
    false
  end

  def initialize(x)
    super(x)
    @platform_type = 'avhrr'
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
    @type = @name_bits[@name_bits.length - 2]
    @encoding = @name_bits[@name_bits.length - 1]
    # http://web6.arsc.edu:8080//UAFGINA/AVHRR/2005/N12.05005.0124/n12.05005.0124.av hrr.L1a.gz
    @archive_path = '/UAFGINA/AVHRR/' + @date_tm.strftime('/%Y/') + @platform.upcase + '.' +                                 @date_tm.strftime('%y%j.%H%M/')
    @url = @path = @archive_path = @archive_path + @name
  end
end
