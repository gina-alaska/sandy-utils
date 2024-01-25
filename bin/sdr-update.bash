#!/bin/bash -l
cd /tmp
source /opt/cspp/SDR_4_0/cspp_sdr_env.sh
sdr_luts.sh >> $HOME/luts-update.log
sdr_ancillary.sh >> $HOME/anc-update.log
