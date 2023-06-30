#!/usr/bin/env python
"""Converts a CSP netcdf VAF heat points file to an AWIPS netcdf file
   that can be read with the dmw plug-in. Ver: 2.0"""

import argparse
import shutil
from shutil import copy, copyfileobj
import os
import netCDF4
import sys
import random
import datetime
from datetime import datetime, timedelta
from time import strftime,strptime
import numpy as np

##############################################################
# read command line arguments and sets 

def _process_command_line():
    """Process the command line arguments.
    Return an argparse.parse_args namespace object.
    """
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '-v', '--verbose', action='store_true', help='verbose flag'
    )
    parser.add_argument(
        '-r', '--readonly', action='store_true', help='Read h5 file and report'
    )
    parser.add_argument(
        '-f', '--filepath', action='store', required=True,
        help='netCDF file path'
    )
    args = parser.parse_args()
    return args

##############################################################
# create a new pathname for the netcdf file using segments of the
# input file name

def getnewpath(filepath):

    sat_dict = {'j02':'NOAA-21','j01':'NOAA-20','npp':'S-NPP'}
    #
    filename = os.path.basename(filepath)
    dirname = os.path.dirname(filepath)
    if len(dirname) == 0:
       dirname = '.'
    # parse the filename to extract the pass times and type of satellite
    fparts = filename.split('_')
    # parse out the date/time from the input hdf filename
    # this is used in the filename and as a global attribute
    # first get the start date/time
    sdatestr = "{}{}".format(fparts[2][1:],fparts[3][1:6])
    edatestr = "{}{}".format(fparts[2][1:],fparts[4][1:6])
    sdate = datetime.strptime(sdatestr,"%Y%m%d%H%M%S")
    edate = datetime.strptime(edatestr,"%Y%m%d%H%M%S")
    if sdate > edate:
       edate = edate - timedelta(days=1)

    ## next determine the file date format 
    filedtstring = sdate.strftime("%Y%m%dT%H%M%S")
    #print filedtstring
    ## assign the satellite name 
    satname = fparts[1]
    ## generate a random number to add to the file name
    rnum = random.randrange(1,10000,1)
    ## now create the new filename 
    newfname = "{}/UAF_viirs_fires_{}_{}_{:05d}.nc".format(dirname,
      sat_dict[satname],filedtstring,rnum)
    #print newfname

    return newfname,sdate,edate,satname
    #
###############################################################
# read all the numpy data to a netcdf file and return the arrays

def read_vaf_ncfile(filepath,lat,lon,frp,conf,PA):

    try:
       ncfh = netCDF4.Dataset(filepath, 'r')
    except IOError:
       print ('Error opening {}').format(filepath)
       raise SystemExit
    except OSError:
       print ('Error accessing {}').format(filepath)
       raise SystemExit

    # read dimensions
    nc_dims = ncfh.dimensions
    nc_dims = ncfh.groups['Fire Pixels'].dimensions
    #print "NetCDF dimension information:"
    num_dim = 0
    numpts = 0
    for dim in nc_dims:
        print ("\tName:", dim)
        #if dim == 'phony_dim_0':
        if dim == 'nfire':
           numpts = len(ncfh.groups['Fire Pixels'].dimensions[dim])
    print ("num pts: {}".format(numpts))
    if numpts > 0:
       lat = ncfh.groups['Fire Pixels'].variables['FP_latitude'][:]
       lon = ncfh.groups['Fire Pixels'].variables['FP_longitude'][:]
       frp = ncfh.groups['Fire Pixels'].variables['FP_power'][:]
       conf = ncfh.groups['Fire Pixels'].variables['FP_confidence'][:]
       PA = ncfh.groups['Fire Pixels'].variables['FP_PersistentAnomalyCategory'][:]
    else:
       lat=-999.
       lon=-999.
       frp=-999.
       conf=-999.
       PA=-999.

    ncfh.close()
    #for i in range(0,numpts):
    #   print "{}/{} frp={}  conf={}".format(lat[i],lon[i],frp[i],conf[i])

    return(numpts,lat,lon,frp,conf,PA)
    #

###############################################################
# write all the numpy data to a netcdf file and add the needed
# global and variable attributes

def write_viirsfires_ncfile(filepath,sdate,edate,satname,numpts,lat,lon,frp,conf,PA):

    sat_dict = {'j02':'NOAA-21','j01':'NOAA-20','npp':'S-NPP'}
    try:
       ncfh = netCDF4.Dataset(filepath, 'w', format='NETCDF4')
    except IOError:
       print ('Error opening {}').format(filepath)
       raise SystemExit
    except OSError:
       print ('Error accessing {}').format(filepath)
       raise SystemExit

    #debug output
    #print "Latitude:",lat
    #print "Longitude:",lon
    #print "Dim:{}".format(numpts)

    # set dimensions
    fdimid = ncfh.createDimension('nfire', None)
    dmwdimid = ncfh.createDimension('dmw_band', 1)
    # set global attributes
    #setattr(ncfh, "_NCProperties", "version=2,netcdf=4.7.4,hdf5=1.10.5")
    setattr(ncfh, "mission_name", sat_dict[satname])
    sdatestr = sdate.strftime("%Y-%m-%dT%H:%M:%S.0.Z")
    setattr(ncfh, "first_meas_time", sdatestr)
    edatestr = edate.strftime("%Y-%m-%dT%H:%M:%S.0.Z")
    setattr(ncfh, "last_meas_time", edatestr)
    setattr(ncfh, "production_site", "UAF")
  
    # create variables
    latvar = ncfh.createVariable('lat','f8','nfire')
    latvar.units = 'degrees_north'
    latvar.long_name = 'latitude'
    lonvar = ncfh.createVariable('lon','f8','nfire')
    lonvar.units = 'degrees_east'
    lonvar.long_name = 'longitude'
    frpvar = ncfh.createVariable('FP_power','f4','nfire')
    frpvar.units = 'MW'
    frpvar.long_name = 'Fire radiative power' 
    confvar = ncfh.createVariable('FP_confidence','f4','nfire')
    confvar.units = '%'
    confvar.long_name = 'Detection confidence' 
    PAvar = ncfh.createVariable('FP_PersistentAnomalyCategory','f4','nfire')
    PAvar.units = '1'
    PAvar.long_name = 'persistent industrial or nature source, 0 none, 1 oil or gas, 2 volcano, 3 solar panel, 4 urban, 5 unclassified' 
    tmvar = ncfh.createVariable('time','f8','nfire')
    tmvar.units = 's'
    tmvar.long_name = 'VIIRS time_coverage_start as array'
    DQFvar = ncfh.createVariable('DQF','f8','nfire')
    DQFvar.units = '1'
    DQFvar.long_name = 'Delineator of zero vs non zero FP_Confidence'
    DQFvar.flag_values = 0, 1
    DQFvar.flag_meanings = 'FP_confidence is gt zero, FP_confidence is eq to zero"'
    dmwvar = ncfh.createVariable('band_id','b','dmw_band')
    dmwvar.longname = 'Generic band identifier for use in AWIPS dmw plugin'
    dmwvar.units = '1'
 
    #now write to the data arrays
    latvar[:] = lat
    lonvar[:] = lon
    frpvar[:] = frp
    confvar[:] = conf
    PAvar[:] = PA

    #set time in unix secs...dqf flags...persistent anomalies
    secs = []
    dqf = []
    pa = []
    for i in range(0,numpts):
       secs.append(sdate.strftime("%s"))
       pa.append(0)
       dqf.append(0)
       if conf[i] == 0:
          dqf = 1
    # 
    tmvar[:] = secs 
    DQFvar[:] = dqf
    PAvar[:] = pa
    dmw = 99
    dmwvar[:] = dmw

    ncfh.close()

##############################################################
def main():
    """Call to run script."""
    args = _process_command_line()
    if not os.path.exists(args.filepath):
        print ("File not found: {}").format(args.filepath)
        raise SystemExit
   
    # define empty lists
    lat = []
    lon = []
    frp = []
    conf = []
    PA = []

    # read the CSPP i-band netcdf file
    filepath = args.filepath
    numpts,lat,lon,frp,conf,PA = read_vaf_ncfile(filepath,lat,lon,frp,conf,PA)
    if numpts == 0:
       print ("No points found")
       return   
    else:
       if args.verbose:
          print ("Fire points: {}".format(numpts))
 
    # Determine the new netcdf filepath for containing the data
    newfilepath,sdate,edate,satname = getnewpath(filepath)
    if args.verbose:
       print ("New file: {}".format(newfilepath))

    # read the CSPP i-band netcdf file
    #numpts,lat,lon,frp,conf = read_vaf_ncfile(filepath,lat,lon,frp,conf)
    
    if args.verbose:
       print ("Latitude: {} Longitude: {}  FRP: {}".format(lat,lon,frp))

    if args.readonly:
       print ("No conversion requested. Reporting output...")
       # determine the max and min values of the numpy array
       # make sure negative values are set to fill value
       latnan = np.where(lat < -900, np.nan, lat) 
       lonnan = np.where(lon < -900, np.nan, lon)
       frpnan = np.where(frp < 0, np.nan, frp) 
       confnan = np.where(conf < 0, np.nan, conf) 
       PAnan = np.where(conf < 0, np.nan, PA) 
       # define the max/min variables
       latmin = np.nanmin(latnan)
       latmax = np.nanmax(latnan)
       lonmin = np.nanmin(lonnan)
       lonmax = np.nanmax(lonnan)
       frpmin = np.nanmin(frpnan)
       frpmax = np.nanmax(frpnan)
       confmin = np.nanmin(confnan)
       confmax = np.nanmax(confnan)
       PAmin = np.nanmin(PAnan)
       PAmax = np.nanmax(PAnan)
       print ("Lat max={}  min={}".format(latmax, latmin))
       print ("Lon max={}  min={}".format(lonmax, lonmin))
       print ("FRP max={}  min={}".format(frpmax, frpmin))
       print ("Conf max={}  min={}".format(PAmax, PAmin))
       print ("Panom max={}  min={}".format(PAmax, PAmin))
    else:
       # write to the new file
       write_viirsfires_ncfile(newfilepath,sdate,edate,satname,numpts,lat,lon,frp,conf,PA)
       #print ("Converted file: {}").format(newfilepath)
       print ("Converted file: {}".format(newfilepath))
       if args.verbose:
          print ("done")
    return

if __name__ == '__main__':
    # this is only executed if the script is run from the command line
    main()
