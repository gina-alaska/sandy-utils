#!/bin/bash -l
cd 

VERSION=$(cat ~/build/VERSION)

echo "Version is " $VERSION

echo "Setting up Conda.."
rm -rf /opt/gina/sandy-utils-$VERSION
conda config --add channels conda-forge
conda create -y -p /opt/gina/sandy-utils-$VERSION gdal ruby=2.6.5 libffi pkg-config gxx_linux-64 conda-pack git
conda activate /opt/gina/sandy-utils-$VERSION

#echo "Conda setup."
echo "Installing ruby gems.."
export GEM_HOME="/opt/gina/sandy-utils-$VERSION/vendor/bundle"
export GEM_PATH="/opt/gina/sandy-utils-$VERSION:/opt/gina/sandy-utils-$VERSION/vendor/bundle"



echo "setting ld library path.."
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/gina/sandy-utils-$VERSION/lib

echo "Copying sandy-utils to build area.."
cd ~/build
cp -rv lib/processing_framework* /opt/gina/sandy-utils-$VERSION/lib/
cp -rv config /opt/gina/sandy-utils-$VERSION/config
cp -v  Gemfile Gemfile.lock config README.md VERSION CHANGELOG.md  notes.md LICENSE Rakefile /opt/gina/sandy-utils-$VERSION
mkdir -p /opt/gina/sandy-utils-$VERSION/tools
./build_bin_stubs.rb bin/*

echo "Installing gems required for Sandy-utils.."
cd /opt/gina/sandy-utils-$VERSION
bundle install --deployment
echo "Done with  ruby gems.."

echo "Installing Processing Utils"
cd /opt/gina/sandy-utils-$VERSION
git clone git@github.com:gina-alaska/processing-utils.git
cd processing-utils
bundle install --binstubs
bin/rake

echo "Building Dan's Scripts"
cd ~/build
git clone git@github.com:gina-alaska/dans-gdal-scripts.git
cd dans-gdal-scripts
./autogen.sh
./configure  --prefix=/opt/gina/sandy-utils-$VERSION
make
make install


echo "Ddditional Environment Setting.."
echo export VERSION=$VERSION > /opt/gina/sandy-utils-$VERSION/env.sh
echo source /opt/gina/sandy-utils-$VERSION/bin/activate >> /opt/gina/sandy-utils-$VERSION/env.sh
echo export GEM_HOME="/opt/gina/sandy-utils-$VERSION/vendor/bundle" >> /opt/gina/sandy-utils-$VERSION/env.sh 
echo export GEM_PATH="/opt/gina/sandy-utils-$VERSION:/opt/gina/sandy-utils-$VERSION/vendor/bundle"  >> /opt/gina/sandy-utils-$VERSION/env.sh
echo export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/opt/gina/sandy-utils-$VERSION/lib >> /opt/gina/sandy-utils-$VERSION/env.sh
echo export PATH=\$PATH:/opt/gina/sandy-utils-$VERSION/processing-utils/bin >> /opt/gina/sandy-utils-$VERSION/env.sh


echo "Making package..."
cd ~/build
SB_TARBALL="sandy-utils-$VERSION.pre.tar.gz"
rm  $SB_TARBALL
conda pack -q --n-threads -1 --compress-level 0 -o $SB_TARBALL
rm -rf ~/build/sandy-utils-$VERSION
mkdir  ~/build/sandy-utils-$VERSION
cd ~/build/sandy-utils-$VERSION
tar -xf ~/build/$SB_TARBALL
cd ~/build
cp build_log.txt sandy-utils-$VERSION/
tar --bzip2 -cf sandy-utils-$VERSION.tar.bz2 sandy-utils-$VERSION

