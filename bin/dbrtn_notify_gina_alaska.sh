#!/bin/bash
# UW SSEC Direct Broadcast Realtime Network
#    New File Notification Script
#    Version 0.2
#
# This script is used to notify DbRTN that a new file is available for ingest
# into the network. It should be run immediately AFTER a file has been
# generated and made available at the download location.
#
# These scripts are generated for each individual participating direct
# broadcast site and should not be modified.
#
# This script was generated for gina-alaska at 2014-09-04 20:45:57.771919.
#
# For support please see http://dbrtn.ssec.wisc.edu
#

# Client specific API Key generated by DbRtn
# APIKEY=$DBRTN_APIKEY
# APISECRET=$DBRTN_APISECRET

# Server URL
DBRTN_URL=http://dbrtn.ssec.wisc.edu/api/v1

# true when -v provided
verbose=
# true when -d provided
dryrun=


function print_usage() {
    echo "Usage: $0 [-hvdp] <product> <pass-date:YYYYMMDD> <pass-time:HHMMSS> <url>"
}


function print_help() {
    echo
    print_usage
    cat <<EOF

Notify the DB Realtime Network of a new file. At the time this script is called
the file for which this notification is for should already be available for
the DB Realtime Network ingestors to download. This can be any HTTP or FTP
server to which the ingestors have access.

Options:
    -h  Print this help message
    -v  Enable verbose output
    -d  Perform a dryrun request. For a dryrun all request data will be send to
        the server. If parameter parsing fails error messages will be provided.
        If parameter parsing succeeds the server will attempt to download the
        file using the URL provided providing status of the overall dryrun.
        The server will not return until the request is completed as stated. A
        non dryrun request normally does not wait for the download to complete.
    -p  Print a list of the well-known product types, then exit

Arguments:
    product     A product string in the format: <satellite>:<sensor>:<type>.
                valid characters include 0-9, a-z, _ and -. If the product
                string is not one of the well know products (see the -p option)
                it may not be downloaded by the ingestors.
    pass-date   The start date of the overpass for which this data is for in
                the format YYYYMMDD.
    pass-time   The start time of the overpass for which this data is for in
                the format HHMMSS.
    url         URL where the DB Realtime Network ingestors can download the
                file.

EOF
}


function log () {
    echo "$(date) [DbRtn $1] $2"
}

function exit_error() {
    if [[ "$1" ]]; then
        log ERROR "$1"
    fi
    exit 1
}


function print_products() {
    echo "Well-known products (<satellite>:<sensor>:<type>)"
    curl_cmd="curl ${DBRTN_URL}/products"
    eval "${curl_cmd}"
    echo
    exit 0
}

# see dbrtnweb.auth.ApiQueryString
function sign_query_string () {
    local query_string=$1
    if [ -z ${query_string} ]; then
    exit_error "Internal error, function missing parameter"
    fi
    echo $(python <<EOF
import sys, time, hmac, urlparse
try:
    params = {}
    for pair in "${query_string}".split('&'):
        k, v = pair.split('=')
        if k not in params:
            params[k] = []
        params[k].append(v)
    params['timestamp'] = ['%.0f' % time.time()]
    signed_query_str = ""
    signed = hmac.new("${APISECRET}")
    for key in sorted(params.keys()):
        for val in sorted(params[key]):
            param_str = '&' + '='.join((key, val))
            signed.update(param_str)
            signed_query_str += param_str
    print signed_query_str + "&signature=" + signed.hexdigest()
    sys.exit(0)
except Exception, err:
    if "${debug}":
        raise
sys.exit(1)
EOF
)
}


while getopts "s:h?vpd" opt; do
    case "$opt" in
    h|\?)
        print_help
        exit 0
        ;;
    v)  verbose=1
        ;;
    p)  print_products
        ;;
    d)  dryrun=1
        ;;
    s)  station=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))

if [ $# == 0 ]; then
    print_help
    exit_error
fi

if [[ $station == "uafgina" ]]; then
  APIKEY=$DBRTN_UAFGINA_APIKEY
  APISECRET=$DBRTN_UAFGINA_APISECRET
fi

if [[ $station == "gilmore" ]]; then
  APIKEY=$DBRTN_GILMORE_APIKEY
  APISECRET=$DBRTN_GILMORE_APISECRET
fi

# construct query string parameters from parsed args
product=$1
passdate=$2
passtime=$3
download_url=$4
params="date=${passdate}&download_url=${download_url}&product=${product}"
if [[ ${dryrun} ]]; then
    params="${params}&dryrun=true"
fi
params="${params}&start=${passtime}&apiKey=${APIKEY}"
if [[ ${verbose} ]]; then
    echo "Query string: ${params}"
fi

# sign query string for API authentication
params=$(sign_query_string ${params})
if [[ ${verbose} ]]; then
    echo "Signed query string: ${params}"
fi


# create url to api method with signed query string parameters
url="${DBRTN_URL}/files?${params}"

# construct curl command from provided arguments
curl_cmd="curl $([[ ${verbose} ]] && echo --verbose)"
curl_cmd="${curl_cmd} --silent --show-error --max-time 10 --request PUT \"${url}\""

if [[ ${verbose} ]]; then
    log DEBUG "${curl_cmd}"
fi

# run the curl command, saving the output
curl_output=$(eval ${curl_cmd} 2>&1)
curl_status=$?

if [[ ${verbose} ]]; then
    echo "${curl_output}"
fi

# For a dry run we have to check the returned output for known error strings.
if [[ ${dryrun} ]] &&
   [[ "${curl_output}" =~ [Ff]ailed ]]; then
    exit_error "${curl_output}"

# In all other cases any output at all indicates an error.
elif [[ ${#curl_output} > 0 ]]; then
    exit_error "${curl_output}"
fi

exit 0
