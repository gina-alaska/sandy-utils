sandy-utils
===========

processing bits attached to the sandy (and other) data processing streams. 

This toolset is intended to provide a (fairly) uniform interface for processing GINA's NRT data. 

basic structure (ruby gem style):
* sandy-utils
  * bin 
    * cris_awips.rb  
      * _SNPP CRIS L1 -> AWIPS_
    * rtstps.rb		
      * _Does Raw -> L0/RDR processing for SNPP, TERRA, and AQUA._
    * snpp_edr.rb  
      * _SNPP sdr -> edr_
    * snpp_sdr.rb  
      * _SNPP rdr -> sdr_
    * viirs_awips.rb
      * _SNPP VIIRS L1 -> AWIPS_
  * lib
    * processing_framework.rb  _(includes everything)_
    * processing_framework/
      * version.rb 
      * other shared stuff
  * config  _Each tool in bin has a config file_
    * cris_awips.yml 
    * rtstps.yml 
    * snpp_edr.yml
    * snpp_sdr.yml
    * viirs_awips.yml


###Notes
===========
Each tool should provide a "--help" option showing a brief description of what it does, and how to use it. 
```
[jcable@spam sandy-utils]$ ./bin/rtstps.rb --help
Usage:
    rtstps.rb [OPTIONS]

  This tool does CCSDS unpacking using Rtstps for SNPP, AQUA, and TERRA.

Options:
    -c, --config config           The config file. Using ./bin/../config/rtstps.yml as the default. (default: "./bin/../config/rtstps.yml")
    -i, --input input             The input file. 
    -h, --help                    print help
    -b, --basename basename       The basename of the data to be processed. For example npp.14300.1843 .  Appended to --outputdir if included.
    -o, --outdir outdir           The output directory. If --basename is included, it is appended to this.
    -t, --tempdir tempdir         The temp directory, used for working space. A sub directory will made inside this named after the basename. (default: $PROCESSING_TEMPDIR)
```


###Common arguments
  * __tempdir__
    * working or temp directory to use.  Also controlled via $PROCESSING_TEMPDIR . 
  * __outdir__
    * output directory
  * __config__ 
    * overrides the use of the config/util.yml config file, where util is the name of the util
  * __processors__
    * The number of processors to use. Also controlled via $PROCESSING_NUMBER_OF_CPUS .
