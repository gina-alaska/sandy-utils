#!/bin/bash -l
#update TLEs for AAPP

exec &>> "$HOME/tle_update.log"

. "$AAPP_PREFIX/ATOVS_CONF"
/opt/aapp/AAPP_8.12/AAPP_8.12/AAPP/bin/get_tle
