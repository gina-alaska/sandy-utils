#!/usr/bin/env python3
"""Get and set attributes on a satellite netcdf file. Ver: 1.3"""

import argparse
import shutil
from shutil import copy, copyfileobj
import os
import sys
import numpy as np
from netCDF4 import Dataset

def _process_command_line():
    """Process the command line arguments.

    Return an argparse.parse_args namespace object.
    """
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '-v', '--verbose', action='store_true', help='verbose flag'
    )
    parser.add_argument(
        '-f', '--filepath', action='store', required=True,
        help='netCDF file path'
    )
    args = parser.parse_args()
    return args

##############################################################3
def wmo_header_block(clat, clon):

    if ( -35.0 <= clat < 37.0 and 270.0 <= clon <= 325.0 ):
          wmostr="IUTN01"
    elif ( 37.0 <= clat <= 75.0 and 270.0 <= clon <= 325.0 ):
          wmostr="IUTN02"
    elif ( -35.0 <= clat < 37.0 and 251.0 <= clon < 270.0 ):
          wmostr="IUTN03"
    elif ( 37.0 <= clat <= 75.0 and 251.0 <= clon < 270.0 ):
          wmostr="IUTN04"
    elif ( -35.0 <= clat < 42.0 and 220.0 <= clon < 251.0 ):
          wmostr="IUTN05"
    elif ( 42.0 <= clat <= 75.0 and 232.0 <= clon < 251.0 ):
          wmostr="IUTN06"
    elif ( 42.0 <= clat < 52.0 and 220.0 <= clon < 232.0 ):
          wmostr="IUTN06"
    elif ( -35.0 <= clat < 50.0 and 180.0 <= clon < 220.0 ):
          wmostr="IUTN07"
    elif ( -35.0 <= clat < 50.0 and 130.0 <= clon < 180.0 ):
          wmostr="IUTN08"
    elif ( 42.0 <= clat <= 75.0 and 232.0 <= clon < 251.0 ):
          wmostr="IUTN06"
    elif ( 42.0 <= clat < 52.0 and 220.0 <= clon < 232.0 ):
          wmostr="IUTN06"
    elif ( -35.0 <= clat < 50.0 and 180.0 <= clon < 220.0 ):
          wmostr="IUTN07"
    elif ( -35.0 <= clat < 50.0 and 130.0 <= clon < 180.0 ):
          wmostr="IUTN08"
    elif ( 52.0 <= clat <= 75.0 and 220.0 <= clon < 232.0 ):
          wmostr="IUTN09"
    elif ( 50.0 <= clat <= 75.0 and 130.0 <= clon < 220.0 ):
          wmostr="IUTN09"
    else:
          wmostr="IUTN06"

    return wmostr

##############################################################3

def fix_nucaps_file(filepath):

    nodice = 2
    if "_j01_" in filepath:
       nodice = 1
    elif "_npp_" in filepath:
       nodice = 1
    elif "_m01_" in filepath:
       nodice = 0
    elif "_m03_" in filepath: 
       nodice = 0
    else:
       print ("Unknown file type: {}").format(filepath)

    newfilepath = filepath+".tmp"
    copy(filepath, newfilepath)

    try:
       cdf_fh = Dataset(newfilepath, 'a', format='NETCDF4')
    except IOError:
       print ('Error opening {}').format(newfilepath)
       raise SystemExit
    except OSError:
       print ('Error accessing {}').format(newfilepath)
       raise SystemExit

    #Change attribute string: time_coverage_start
    attrname="time_coverage_start"
    attr_value = getattr(cdf_fh, attrname)
    attr_new = attr_value[0:19]+"Z"
    setattr(cdf_fh, attrname, attr_new)
    # save the start time vrbls
    dom = attr_value[8:10]
    hr = attr_value[11:13]
    mn = attr_value[14:16]
    sec = attr_value[17:19]

    # Metop soundings need to add a new dimension
    if nodice == 0:
       cdf_fh.createDimension("Number_of_CrIS_FORs", 690)

    #Change attribute string: time_coverage_end
    attrname="time_coverage_end"
    attr_value = getattr(cdf_fh, attrname)
    attr_new = attr_value[0:19]+"Z"
    setattr(cdf_fh, attrname, attr_new)

    #determine the center lat/lon to assign a WMO header
    lats = cdf_fh.variables['Latitude'][:]
    lons = cdf_fh.variables['Longitude'][:]
    minlat = np.min(lats)
    maxlat = np.max(lats)
    minlon = np.min(lons)
    maxlon = np.max(lons)
    #print ("MxMn lat = {}/{} MxMn lon = {}/{}").format(minlat, maxlat, minlon, maxlon)
    clat=(minlat + maxlat)/2
    clon=(minlon + maxlon)/2
    if clon < 0.0:
       clon=clon+360
    #clat=60.
    #clon=240
    #print ("Center lat/lon in 360 framework: {}/{}").format(clat,clon)

    #Change attribute string to "platform_name"
    #rtn = cdf_fh.renameAttribute("satellite_name", "platform_name")
    attr_value = getattr(cdf_fh, "platform_name")
    cdf_fh.satellite_name = attr_value

    #Change these variable names:
    rtn = cdf_fh.renameVariable("Latitude", "Latitude@NUCAPS_EDR")
    rtn = cdf_fh.renameVariable("Longitude", "Longitude@NUCAPS_EDR")
    rtn = cdf_fh.renameVariable("Skin_Temperature", "Skin_Temperature@NUCAPS_EDR")
    rtn = cdf_fh.renameVariable("Surface_Pressure", "Surface_Pressure@NUCAPS_EDR")
    rtn = cdf_fh.renameVariable("Topography", "Topography@NUCAPS_EDR")
    rtn = cdf_fh.renameVariable("View_Angle", "View_Angle@NUCAPS_EDR")
    rtn = cdf_fh.renameVariable("Effective_Pressure", "Effective_Pressure@NUCAPS_EDR")
    rtn = cdf_fh.renameVariable("H2O_MR", "H2O_MR@NUCAPS_EDR")
    rtn = cdf_fh.renameVariable("Liquid_H2O_MR", "Liquid_H2O_MR@NUCAPS_EDR")
    rtn = cdf_fh.renameVariable("O3_MR", "O3_MR@NUCAPS_EDR")
    rtn = cdf_fh.renameVariable("Pressure", "Pressure@NUCAPS_EDR")
    rtn = cdf_fh.renameVariable("SO2_MR", "SO2_MR@NUCAPS_EDR")
    rtn = cdf_fh.renameVariable("Temperature", "Temperature@NUCAPS_EDR")
    rtn = cdf_fh.renameVariable("Stability", "Stability@NUCAPS_EDR")
    rtn = cdf_fh.renameVariable("Ascending_Descending", "Ascending_Descending@NUCAPS_EDR")
    rtn = cdf_fh.renameVariable("Ice_Liquid_Flag", "Ice_Liquid_Flag@NUCAPS_EDR")
    rtn = cdf_fh.renameVariable("Time", "Time@NUCAPS_EDR")
    rtn = cdf_fh.renameVariable("Quality_Flag", "Quality_Flag@NUCAPS_EDR")
    # Metop sounding files use a different variable name for the FOR values
    if nodice:
       rtn = cdf_fh.renameVariable("CrIS_FORs", "CrIS_FORs@NUCAPS_EDR")
    else:
       rtn = cdf_fh.renameVariable("Dice", "CrIS_FORs@NUCAPS_EDR")

    cdf_fh.close()
    #
    # this section extracts the valid time from the filename
    # it will need revision if the name changes 
    wmoblock = wmo_header_block(clat,clon)
    minnum = int(int(mn)/10)
    wmoidx = "{}{}".format(minnum,sec)
    ddhhmm = "{}{}{}".format(dom,hr,mn)
    #header="\r\r\n830 \r\r\nIUTN06 KNES {}\r\r\n".format(ddhhmmss)
    header="\r\r\n{} \r\r\n{} KNES {}\r\r\n".format(wmoidx,wmoblock,ddhhmm)
    #headerName = "IUTN06_KNES_{}.hdf.{}".format(ddhhmm,wmoidx)
    headerName = "UAF_{}_KNES_{}.hdf.{}".format(wmoblock,ddhhmm,wmoidx)
    #print ("Header = {}").format(headerName)
    with open(headerName, 'wb') as newfh:
        newfh.write(b'\x01')
        #newfh.write(header)
        newfh.write(header.encode('utf8'))
        with open(newfilepath,'rb') as prevfh:
           copyfileobj(prevfh, newfh)
           prevfh.close()
        newfh.close()
        os.remove(newfilepath)
        #print ("awipsfile = ").format(headerName)
        return headerName

##############################################################3

def main():
    """Call to run script."""
    args = _process_command_line()
    #
    if not os.path.exists(args.filepath):
        print ("File not found: {}").format(args.filepath)
        raise SystemExit
   
    filepath = args.filepath
    newfile= fix_nucaps_file(filepath)
    print (newfile)
    return


if __name__ == '__main__':
    # this is only executed if the script is run from the command line
    main()
