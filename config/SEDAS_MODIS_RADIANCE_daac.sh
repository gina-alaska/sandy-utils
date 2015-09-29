#! /bin/csh -f
# @(#)TeraScan Version V3_2 Baseline 06/04/02 18:32:02 GMT

# This script converts IMAPP calibrated HDF scaled integers to 
# either TDF MODIS Radiance units (W/m^2/micrometer/steradian/micron)
# OR MODIS Reflectance units

# Check arguments
if ($#argv != 6) then
  echo " "
  echo "Usage: MODIS_RADIANCE_daac.sh cal250.hdf cal500.hdf cal1000.hdf (reflectance/radiance) (terra-1/aqua-1) GEO.file"
  echo " "
  exit(-1)
endif

set FUNC = MODIS_RADIANCE.sh

# Set MODIS HDF input file names
###############################

set CALFILE_250M=$argv[1]
set CALFILE_500M=$argv[2]
set CALFILE_1000M=$argv[3]
set UNITS=$argv[4]
set SATELLITE=$argv[5]
set GEOFILE=$argv[6]
 
if ($UNITS == '') then
   echo "${FUNC}: Failed - Units should be either reflectance OR radiance"
   exit 1
endif

onintr gotsig

#check environment
if ($?SATDATA == 0) then
  echo "${FUNC}: Failed - SATDATA is not defined"
  exit 1
endif

# Define environmental variables and output directories 
################################

if ($UNITS == radiance) then
   set VARUNITS = W/m^2/micrometer/steradian
else
   set VARUNITS = Reflectance
endif

set CURRTIME = `date -u`

set mfile = Master1km
set TDFFILE = cal1000.tdf
set HFILE = cal500.tdf
set QFILE = cal250.tdf
set TRASH = sub.tdf
set TDF = final.tdf
set TDF2 = final.tdf2
echo ${FUNC}: Starting Level1b $UNITS conversion `date -u`...


#Convert HDF output to TDF and apply earth transform
##################################################

hdftotdf \
        include_vars='EV_1KM_RefSB' \
        shortname='yes' \
	tdf_var_attrs='yes' \
$CALFILE_1000M \
$TDFFILE

set STATUS = $status
if ($STATUS != 0) exit $STATUS

editdim \
        dimname='10*nscans:MODIS_SWATH_Type_L1B' \
        newname='1000M_line' \
        varname='<same>' \
        scale='<same>' \
        offset='<same>' \
        coord='3' \
$TDFFILE

editdim \
        dimname='Max_EV_frames:MODIS_SWATH_Type' \
        newname='1000M_sample' \
        varname='<same>' \
        scale='<same>' \
        offset='<same>' \
        coord='2' \
$TDFFILE

editdim \
        dimname='Band_1KM_RefSB:MODIS_SWATH_Type' \
        newname='1000M_channels' \
        varname='<same>' \
        scale='<same>' \
        offset='<same>' \
        coord='<same>' \
$TDFFILE
 
set STATUS = $status
if ($STATUS != 0) exit $STATUS
 
set YY = `echo $CALFILE_1000M | cut -c2-5`
set JDAY = `echo $CALFILE_1000M | cut -c6-8`
set PDATE = `echo $YY"."$JDAY`
set HH = `echo $CALFILE_1000M | cut -c9-10`
set MM = `echo $CALFILE_1000M | cut -c11-12`
set SS = `echo $CALFILE_1000M | cut -c13-14`
set PASSTIME = `echo $HH":"$MM":"$SS`
set DIMS = `getdim include_vars='' annotate=n printout=n $TDFFILE`
echo "Pass date (YYYY.DDD) is $PDATE & pass time (GMT) is $PASSTIME"

satmaster \
        satellite=$SATELLITE \
        sensor='modis' \
        geo_correct='no' \
        pass_date=$PDATE \
        start_time=$PASSTIME \
        delta_line='1' \
        num_lines=$DIMS[2] \
        delta_sample='1' \
        start_sample='1' \
        num_samples=$DIMS[3] \
$mfile
 
echo " satmaster done"

subset \
        include_vars='-master' \
        clip_dims= \
        instantiate='y' \
$mfile \
$TDF

/bin/rm $mfile

set STATUS = $status
if ($STATUS != 0) exit $STATUS
 
echo " Converting 250M Channels..."
 
hdftotdf \
        include_vars='EV_250_RefSB' \
        shortname='yes' \
	tdf_var_attrs='yes' \
$CALFILE_250M \
$QFILE


editdim \
        dimname='40*nscans:MODIS_SWATH_Type_L1B' \
        newname='250M_line' \
        varname='<same>' \
        scale='0.25' \
        offset='-.375' \
        coord='3' \
$QFILE
 
editdim \
        dimname='4*Max_EV_frames:MODIS_SWATH_Typ' \
        newname='250M_sample' \
        varname='<same>' \
        scale='0.25' \
        offset='-.375' \
        coord='2' \
$QFILE
 
editdim \
        dimname='Band_250M:MODIS_SWATH_Type_L1B' \
        newname='250M_channels' \
        varname='<same>' \
        scale='<same>' \
        offset='<same>' \
        coord='<same>' \
$QFILE

 
@ i = 1
foreach CH ( 1 2 )

if ($UNITS == radiance) then
set QSCAL = `varinfo var_name="EV_250_RefSB" attr_name="radiance_scales" $QFILE`
set QOFF = `varinfo var_name="EV_250_RefSB" attr_name="radiance_offsets" $QFILE`
else
set QSCAL = `varinfo var_name="EV_250_RefSB" attr_name="reflectance_scales" $QFILE`
set QOFF = `varinfo var_name="EV_250_RefSB" attr_name="reflectance_offsets" $QFILE`
endif
 
subset include_vars="EV_250_RefSB" clip_dims='250M_channels' \
   range_pairs=$CH,$CH instantiate='no' $QFILE $TRASH
varname old_var_name="EV_250_RefSB" new_var_name=x_$CH $TRASH
set newoffset = `smath "-$QSCAL[$i]*$QOFF[$i]"`
editvar include_vars=x_$CH var_units=$VARUNITS bad_value='' \
    scale_factor=$QSCAL[$i] scale_offset=$newoffset valid_min='' valid_max='' $TRASH
copyvar include_vars='x*' overwrite_vars='yes' $TRASH $TDF
@ i = $i + 1
end
        varname old_var_name=x_1 new_var_name=modis_ch01 $TDF
        varname old_var_name=x_2 new_var_name=modis_ch02 $TDF
 
 
/bin/rm $QFILE $TRASH

echo " Cleaning up files..."
 
echo " Converting 500M Channels..."
 
hdftotdf \
        include_vars='EV_500_RefSB' \
        shortname='yes' \
	tdf_var_attrs='yes' \
$CALFILE_500M \
$HFILE

set STATUS = $status
if ($STATUS != 0) exit $STATUS
 
editdim \
        dimname='20*nscans:MODIS_SWATH_Type_L1B' \
        newname='500M_line' \
        varname='<same>' \
        scale='0.5' \
        offset='-.25' \
        coord='3' \
$HFILE
 
editdim \
        dimname='2*Max_EV_frames:MODIS_SWATH_Typ' \
        newname='500M_sample' \
        varname='<same>' \
        scale='0.5' \
        offset='-.25' \
        coord='2' \
$HFILE
 
editdim \
        dimname='Band_500M:MODIS_SWATH_Type_L1B' \
        newname='500M_channels' \
        varname='<same>' \
        scale='<same>' \
        offset='<same>' \
        coord='<same>' \
$HFILE

 
@ i = 1
foreach CH ( 1 2 3 4 5 )

if ($UNITS == radiance) then
set HSCAL = `varinfo var_name="EV_500_RefSB" attr_name="radiance_scales" $HFILE`
set HOFF = `varinfo var_name="EV_500_RefSB" attr_name="radiance_offsets" $HFILE`
else
set HSCAL = `varinfo var_name="EV_500_RefSB" attr_name="reflectance_scales" $HFILE`
set HOFF = `varinfo var_name="EV_500_RefSB" attr_name="reflectance_offsets" $HFILE`
endif
 
subset include_vars="EV_500_RefSB" clip_dims='500M_channels' \
   range_pairs=$CH,$CH instantiate='no' $HFILE $TRASH
varname old_var_name="EV_500_RefSB" new_var_name=x_$CH $TRASH
set newoffset = `smath "-$HSCAL[$i]*$HOFF[$i]"`
editvar include_vars=x_$CH var_units=$VARUNITS bad_value='' \
    scale_factor=$HSCAL[$i] scale_offset=$newoffset valid_min='' valid_max='' $TRASH
copyvar include_vars='x*' overwrite_vars='yes' $TRASH $TDF
@ i = $i + 1
end
        varname old_var_name=x_1 new_var_name=modis_ch03 $TDF
        varname old_var_name=x_2 new_var_name=modis_ch04 $TDF
        varname old_var_name=x_3 new_var_name=modis_ch05 $TDF
        varname old_var_name=x_4 new_var_name=modis_ch06 $TDF
        varname old_var_name=x_5 new_var_name=modis_ch07 $TDF
 
 
/bin/rm $HFILE $TRASH

echo " Converting 1KM Reflective Channels..."


@ i = 1
foreach CH ( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 )

if ($UNITS == radiance) then
set REFONESCL = `varinfo var_name="EV_1KM_RefSB" attr_name="radiance_scales" $TDFFILE`
set REFONEOFF = `varinfo var_name="EV_1KM_RefSB" attr_name="radiance_offsets" $TDFFILE`
else
set REFONESCL = `varinfo var_name="EV_1KM_RefSB" attr_name="reflectance_scales" $TDFFILE`
set REFONEOFF = `varinfo var_name="EV_1KM_RefSB" attr_name="reflectance_offsets" $TDFFILE`
endif
 
subset include_vars="EV_1KM_RefSB" clip_dims='1000M_channels' \
   range_pairs=$CH,$CH instantiate='no' $TDFFILE $TRASH
varname old_var_name="EV_1KM_RefSB" new_var_name=x_$CH $TRASH
set newoffset = `smath "-$REFONESCL[$i]*$REFONEOFF[$i]"`
editvar include_vars=x_$CH var_units=$VARUNITS bad_value='' \
    scale_factor=$REFONESCL[$i] scale_offset=$newoffset valid_min='' valid_max='' $TRASH
copyvar include_vars='x*' overwrite_vars='yes' $TRASH $TDF
@ i = $i + 1
end
 
 
        varname old_var_name=x_1 new_var_name=modis_ch08 $TDF
        varname old_var_name=x_2 new_var_name=modis_ch09 $TDF
        varname old_var_name=x_3 new_var_name=modis_ch10 $TDF
        varname old_var_name=x_4 new_var_name=modis_ch11 $TDF
        varname old_var_name=x_5 new_var_name=modis_ch12 $TDF
        varname old_var_name=x_6 new_var_name=modis_ch13L $TDF
        varname old_var_name=x_7 new_var_name=modis_ch13H $TDF
        varname old_var_name=x_8 new_var_name=modis_ch14L $TDF
        varname old_var_name=x_9 new_var_name=modis_ch14H $TDF
        varname old_var_name=x_10 new_var_name=modis_ch15 $TDF
        varname old_var_name=x_11 new_var_name=modis_ch16 $TDF
        varname old_var_name=x_12 new_var_name=modis_ch17 $TDF
        varname old_var_name=x_13 new_var_name=modis_ch18 $TDF
        varname old_var_name=x_14 new_var_name=modis_ch19 $TDF
        varname old_var_name=x_15 new_var_name=modis_ch26 $TDF
 
 
 
/bin/rm $TRASH $TDFFILE
 
echo " Cleaning up files..."

echo " Converting 1KM IR Channels..."

hdftotdf \
        include_vars='EV_1KM_Emissive' \
        shortname='yes' \
	tdf_var_attrs='yes' \
$CALFILE_1000M \
$TDFFILE

set STATUS = $status
if ($STATUS != 0) exit $STATUS

editdim \
        dimname='10*nscans:MODIS_SWATH_Type_L1B' \
        newname='1000M_line' \
        varname='<same>' \
        scale='<same>' \
        offset='<same>' \
        coord='3' \
$TDFFILE

editdim \
        dimname='Max_EV_frames:MODIS_SWATH_Type' \
        newname='1000M_sample' \
        varname='<same>' \
        scale='<same>' \
        offset='<same>' \
        coord='2' \
$TDFFILE

editdim \
        dimname='Band_1KM_Emissive:MODIS_SWATH_T' \
        newname='1000M_channels' \
        varname='<same>' \
        scale='<same>' \
        offset='<same>' \
        coord='<same>' \
$TDFFILE

 
@ i = 1
foreach CH ( 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 )

set EMONESCL = `varinfo var_name="EV_1KM_Emissive" attr_name="radiance_scales" $TDFFILE`
set EMONEOFF = `varinfo var_name="EV_1KM_Emissive" attr_name="radiance_offsets" $TDFFILE`
 
subset include_vars="EV_1KM_Emissive" clip_dims='1000M_channels' \
   range_pairs=$CH,$CH instantiate='no' $TDFFILE $TRASH
varname old_var_name="EV_1KM_Emissive" new_var_name=x_$CH $TRASH
set newoffset = `smath "-$EMONESCL[$i]*$EMONEOFF[$i]"`
editvar include_vars=x_$CH var_units='W/m^2/micrometer/steradian' bad_value='' \
    scale_factor=$EMONESCL[$i] scale_offset=$newoffset valid_min='' valid_max='' $TRASH
copyvar include_vars='x*' overwrite_vars='yes' $TRASH $TDF
@ i = $i + 1
end
 
        varname old_var_name=x_1 new_var_name=modis_ch20 $TDF
        varname old_var_name=x_2 new_var_name=modis_ch21 $TDF
        varname old_var_name=x_3 new_var_name=modis_ch22 $TDF
        varname old_var_name=x_4 new_var_name=modis_ch23 $TDF
        varname old_var_name=x_5 new_var_name=modis_ch24 $TDF
        varname old_var_name=x_6 new_var_name=modis_ch25 $TDF
        varname old_var_name=x_7 new_var_name=modis_ch27 $TDF
        varname old_var_name=x_8 new_var_name=modis_ch28 $TDF
        varname old_var_name=x_9 new_var_name=modis_ch29 $TDF
        varname old_var_name=x_10 new_var_name=modis_ch30 $TDF
        varname old_var_name=x_11 new_var_name=modis_ch31 $TDF
        varname old_var_name=x_12 new_var_name=modis_ch32 $TDF
        varname old_var_name=x_13 new_var_name=modis_ch33 $TDF
        varname old_var_name=x_14 new_var_name=modis_ch34 $TDF
	varname old_var_name=x_15 new_var_name=modis_ch35 $TDF
        varname old_var_name=x_16 new_var_name=modis_ch36 $TDF


if ($UNITS == reflectance) then
   set FNAME = REFLECTANCE
else
   set FNAME = RADIANCE
endif

# Kengle put in GCP postion fixing #
# Now try to improve earth location using geo file
##################################################

set HDF = $GEOFILE

hdftotdf include_vars="Latitude Longitude attitude_angles" \
         shortname=yes tdf_var_attrs=yes $HDF GEO_postion

#if ($status != 0) goto failed

imapp_modis_gcp ./GEO_postion $TDF

#if ($status != 0) goto failed


if ($SATELLITE == aqua-1) then
setname fix_time=no template=a1.yyddd.hhmm."$FNAME"_tdf $TDF
else
setname fix_time=no template=t1.yyddd.hhmm."$FNAME"_tdf $TDF
endif

/bin/rm $TDFFILE $TRASH ./GEO_postion

echo " Cleaning up files..."

#/bin/rm $mfile $L1AFILE $GEOFILE $CALFILE_250M $CALFILE_500M CALFILE_1000M $OBCFILE $BOXFILE core
echo "Successful L1B Radiance conversion."
exit 0
