sandy-utils
===========

processing bits attached to the sandy (and other) data processing streams. 

This toolset is intented to provide a (fairly) uniform interface for processing GINA's NRT data. 

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
** config  _Each tool in bin has a config file_
*** cris_awips.yml 
*** rtstps.yml 
*** snpp_edr.yml
*** snpp_sdr.yml
*** viirs_awips.yml

