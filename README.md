sandy-utils
===========

processing bits attached to the sandy (and other) data processing streams. 

This toolset is intented to provide a (fairly) uniform interface for processing GINA's NRT data. 

basic structure (ruby gem style):
* sandy-utils
  * bin 
    * cris_awips.rb  
    * rtstps.rb		Does Raw -> L0/RDR processing for SNPP, TERRA, and AQUA.
    * snpp_edr.rb  
    * snpp_sdr.rb  
    * viirs_awips.rb
  * lib
    * processing_framework.rb (includes everything in sandy/)
    * processing_framework/
      * version.rb 
      * other shared stuff
  * config
    * foo.yml (config for util in bin, named foo) 
