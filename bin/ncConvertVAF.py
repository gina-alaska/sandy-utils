#!/bin/bash
source /opt/gina/sandy-utils-1.7.1-20201216153420/env.sh
if [[ -f $TSCANROOT/etc/tscan.bash_profile ]]; then
    source $TSCANROOT/etc/tscan.bash_profile
fi
exec /opt/gina/sandy-utils-1.7.1-20201216153420/tools/ncConvertVAF.py.real $@

