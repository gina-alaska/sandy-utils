#!/bin/bash
cd 

VERSION=$(cat ~/build/VERSION)

echo "Version is " $VERSION

echo "Setting up Conda.."

wget -q https://repo.anaconda.com/archive/Anaconda3-2020.02-Linux-x86_64.sh
sh ./Anaconda3-2020.02-Linux-x86_64.sh -b -p $HOME/anaconda
. ~/.bashrc

 ~/anaconda/bin/conda init


#conda activate /opt/gina/sandy-utils-$VERSION


#conda create -p /opt/gina/sandy-utils-$VERSION gdal
#conda activate /opt/gina/sandy-utils-$VERSION
#conda config --add channels conda-forge
#conda install ruby=2.6.5
#conda install libffi
#conda install pkg-config
#conda install gxx_linux-64
