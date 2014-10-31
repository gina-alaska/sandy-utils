sandy-utils
===========

processing bits attached to the sandy (and other) data processing streams. 

basic structure (ruby gem style):
* sandy-utils
  * bin 
    * foo (util called foo)
  * lib
    * sandy.rb (includes everything in sandy/)
    * sandy/
      * version.rb 
      * other shared stuff
  * config
    * foo.yml (config for util in bin, named foo) 
