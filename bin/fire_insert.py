import datetime
import os
import sys
import pytz
import pandas as pd
import psycopg2
from psycopg2.extras import execute_batch

# Postgres Table
PG_TABLE = "viirs_active_fire_detections"

#### Input File name structure
#
#              /-date            /-time(end)       /-proc datetime
# AFIMG_j01_d20221208_t1501083_e1502328_b26195_c20221208151348571685_cspp_dev.txt
#        \-sat          \-time(start)

# Input file column defs
COLUMNS = (
    'latitude', 'longitude', 'brightness_temp_k', 'along_scan_res', 'along_track_res',
    'confidence_num', 'rad_power_mw', 'persistent_anomaly_type'
)
CONFIDENCE = {
    7: "Low confidence fire pixel",
    8: "Nominal confidence fire pixel",
    9: "High confidence fire pixel"
}
TABLE_ORDER = [
    'latitude', 'longitude', 'observed_aktime', 'processed_aktime', 'satellite_source',
    'confidence_txt', 'brightness_temp_k', 'rad_power_mw', 'source_file',
    'observed_utctime', 'processed_utctime', 'confidence_num',
    'along_scan_res', 'along_track_res', 'software_ver', 'utcobstime',
    'persistent_anomaly_type'
]

# Time zones we care about
UTCZ = pytz.timezone("UTC")
AKTZ = pytz.timezone("America/Anchorage")

# Non-duplicate insert SQL
INSERT_SQL = '''
    INSERT INTO viirs_active_fire_detections (
        "latitude", "longitude",
        "observed_aktime", "processed_aktime",
        "satellite_source", "confidence_txt",
        "brightness_temp_k", "rad_power_mw",
        "source_file",
        "observed_utctime", "processed_utctime",
        "confidence_num", "along_scan_res", "along_track_res",
        "software_ver", "utcobstime",
        "shape", "persistent_anomaly_type")
    SELECT
        %(latitude)s, %(longitude)s,
        %(observed_aktime)s, %(processed_aktime)s,
        %(satellite_source)s, %(confidence_txt)s,
        %(brightness_temp_k)s, %(rad_power_mw)s,
        %(source_file)s,
        %(observed_utctime)s, %(processed_utctime)s,
        %(confidence_num)s, %(along_scan_res)s, %(along_track_res)s,
        %(software_ver)s, %(utcobstime)s,
        ST_SetSRID(ST_MakePoint(%(longitude)s, %(latitude)s), 4326),
        %(persistent_anomaly_type)s
    WHERE not exists (
        select 	1
        from    viirs_active_fire_detections
        where   ST_Distance(shape::geography, ST_SetSRID(ST_MakePoint(%(longitude)s::double precision, %(latitude)s::double precision),4326)::geography) < 1 and
                utcobstime between %(utcobstime)s - (30 * interval'1 second') and
                %(utcobstime)s + (30 * interval '1 second') and
                satellite_source = %(satellite_source)s
    )
'''

# Extract file name information
def interpolate_file_name ( basename ):
    basename_parts = basename.split('_')

    satellite = basename_parts[1]
    observation = basename_parts[2][1:] + basename_parts[3][1:-3]
    processing = basename_parts[6][1:13]

    # Reformat to RDS satellite type
    if satellite not in ('j01', 'npp', 'j02'):
        print(f'Unknown SATELLITE code: {satellite}')
    else:
        if satellite == "j01":
            satellite = "NOAA-20/GINA"
        else:
            if satellite == 'j02':
                satellite = "NOAA-21/GINA"
            else:
                satellite = "SNPP/GINA"

    print(f"satellite: {satellite}; observation: {observation}, processing {processing}")

    observation = datetime.datetime.strptime(observation, "%Y%m%d%H%M")
    processing = datetime.datetime.strptime(processing, "%Y%m%d%H%M")

    return satellite, observation, processing

# Textify confidence
def conf_str( row ):
    return CONFIDENCE[row] if row in CONFIDENCE else None

# Read processor version from input file
def get_processor_version ( lines ):

    for line in lines:
        if not line.startswith("# version:"):
            continue
        return line.rstrip('\n').split(' ')[-1]

    return None

# Read points file as CSV using pandas
def read_fire_file ( in_file ):

    df = pd.read_csv(in_file, comment='#', header=None)
    df.columns = COLUMNS

    # Add Confidence String
    df["confidence_txt"] = df.apply(lambda row: conf_str( row['confidence_num'] ), axis=1)

    # Add software version
    with open(in_file, 'r') as f:
        df["software_ver"] = get_processor_version( f )

    return df

def localized_string( dt_value, tz_in, tz_out ):
    return tz_in.localize(dt_value).astimezone(tz_out).strftime("%m/%d/%Y %H:%M")

# Compile a pandas DataTable that matches insert PG table
def ingest_fire_file ( in_file ):

    # digest filename for metadata
    basename = in_file.split('/')[-1]
    satellite, observation, processing = interpolate_file_name ( basename )

    # Create a DataFrame of the points
    fire = read_fire_file ( in_file )

    # Localize times as columns
    fire['utcobstime'] = UTCZ.localize( observation )
    fire['observed_aktime'] = localized_string( observation, UTCZ, AKTZ )
    fire['observed_utctime'] = localized_string( observation, UTCZ, UTCZ )
    fire['processed_aktime'] = localized_string( processing, UTCZ, AKTZ )
    fire['processed_utctime'] = localized_string( processing, UTCZ, UTCZ )

    # Add filename & satellite
    fire['satellite_source'] = satellite
    fire['source_file'] = basename

    # Reorder columns
    fire = fire[TABLE_ORDER]
    print(fire)

    return fire

def pg_connection_params ( ):

    return {
       "dbname": "fire_points",
       "user": os.getenv("PG_USERNAME", "gis_admin"),
       "password": os.getenv("PG_PASSWORD"),
       "host": os.getenv("PG_HOST", "rds.fire.local"),
       "port": 5432
    }

# Loop over the data points and insert
def insert_data_into_db ( fire_data ):

    pg_conn = psycopg2.connect( **pg_connection_params() )
    cursor = pg_conn.cursor()

    # Find the ST_* functions
    cursor.execute("SET search_path=public,tiger")
    print(f"{fire_data['source_file'].iloc[0]}")

    ## Get count before adding new detections..
    cursor.execute("select count(1) from viirs_active_fire_detections where source_file=%s", (f"{fire_data['source_file'].iloc[0]}",))
    starting_count = cursor.fetchall()[0][0]
    print(f"Before insert {starting_count} fire detections exist")
    status = execute_batch(cursor,INSERT_SQL, fire_data.to_dict(orient='records') )

    cursor.execute("select count(1) from viirs_active_fire_detections where source_file=%s", (f"{fire_data['source_file'].iloc[0]}",))
    finishing_count = cursor.fetchall()[0][0]

    difference_count = finishing_count-starting_count
    print(f"After insert {finishing_count} fire detections exist, a change of {difference_count}")
    pg_conn.commit()


def ingest (in_file):
    try:
        fire_data = ingest_fire_file ( in_file )        
        insert_data_into_db ( fire_data )
        return True
    except Exception as Err:
        print(f"Failed to ingest {in_file}: {Err}")
        raise Err

    return False


for i in range(1, len(sys.argv)):
    print(f"Ingesting: {sys.argv[i]}")
    ingest(sys.argv[i])
